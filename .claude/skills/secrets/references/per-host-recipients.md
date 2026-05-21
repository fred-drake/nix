# Per-Host SOPS Recipients

When and how to add a host's own age identity as a SOPS recipient on the secrets it reads. This is a server-side pattern, not for workstations.

## When you need this

The two default recipients (`workstation`, `infrastructure`) cover most cases. Reach for a per-host recipient only when one of these is true:

1. **The host runs the workstation home-manager stack on top of NixOS.** HM's `secrets` feature deploys workstation SSH keys as sops-managed symlinks at `~/.ssh/id_*`. Those targets don't exist until HM activates, which happens *after* NixOS-level setupSecrets. So `sops.age.sshKeyPaths = ["/home/<user>/.ssh/id_infrastructure"]` reads a dangling symlink at stage 1 and silently falls back to whatever else it can find (usually nothing useful). Symptom: `failed to decrypt 'X.sops.yaml': Error getting data key: 0 successful groups required, got 0`.

2. **The host's age key location isn't accessible at stage 1.** If `/home` is a separate mount, or the relevant user doesn't exist yet during initrd-systemd activation, anything under `/home` is invisible to setupSecrets. Hetzner servers dodge this because `/root/id_infrastructure` lives on `/`. The host SSH key at `/etc/ssh/ssh_host_ed25519_key` is also on `/` and works the same way.

3. **You want a host to be able to rotate its own identity without touching any other host's key material.**

Gnomeregan is the only host that meets these criteria today. See `infrastructure/references/gnomeregan.md` (in the infrastructure skill) for its specifics.

## Procedure: add a host as a recipient

### 1. Derive the host's age recipient

Run from any machine that can read the host's public SSH key:

```bash
ssh <host> 'sudo cat /etc/ssh/ssh_host_ed25519_key.pub' \
  | nix run nixpkgs#ssh-to-age
```

Output looks like `age1kdu824t8sf07kf94zuakx38dk835fknftpdpsqjv9fjamzxwnvasryg2vm`. Save it — that's the recipient string used everywhere else.

### 2. Save the public key in nix-secrets

By convention, every recipient has a `pubkeys/<name>.pub` file checked into nix-secrets. It's never decrypted — it's documentation:

```bash
ssh <host> 'sudo cat /etc/ssh/ssh_host_ed25519_key.pub' \
  > /path/to/nix-secrets/pubkeys/<host>.pub
```

### 3. Add the recipient to `.sops.yaml`

Append the age recipient (comma-separated) on every `creation_rules` entry that matches paths the host needs to decrypt. Also add the public-key reference comment at the top so the file is self-documenting:

```yaml
# SOPS configuration file
#
# Public AGE keys:
# workstation:    age1g7ta2wz5...
# infrastructure: age1rnarwmx5...
# gnomeregan:     age1kdu824t8...      ← add
creation_rules:
  - path_regex: secrets/host/gnomeregan/.*
    age: age1g7ta2wz5...,age1rnarwmx5...,age1kdu824t8...   ← extended
  - path_regex: secrets/host/ironforge/.*-storage\.sops\.yaml
    age: age1g7ta2wz5...,age1rnarwmx5...,age1kdu824t8...   ← extended (host reads these)
```

The ordering of recipients in each rule doesn't matter for decryption, but keeping `workstation,infrastructure,<host>` consistent makes the diff readable.

### 4. Re-encrypt every existing file the rule touches

`sops updatekeys` rewrites the recipient set on an existing file to match the current `.sops.yaml` rules. Run it from inside nix-secrets:

```bash
cd /path/to/nix-secrets
ssh-to-age -i ~/.ssh/id_ed25519 -private-key > /tmp/workstation-age.key
export SOPS_AGE_KEY_FILE=/tmp/workstation-age.key

for f in secrets/host/gnomeregan/*.sops* secrets/host/ironforge/*-storage.sops.yaml; do
  yes | sops updatekeys "$f"
done
```

**Common gotcha:** files with the `.sops` extension that are actually YAML internally need `--input-type yaml --output-type yaml`. sops infers format from extension and assumes JSON for `.sops`; if you see `Error unmarshalling input json: invalid character 'd' looking for beginning of value`, that's the cause. Retry with explicit type flags.

### 5. Commit + push nix-secrets, bump the flake input

```bash
# In nix-secrets
git add .sops.yaml pubkeys/<host>.pub secrets/
git commit -m "feat(<host>): add host SSH key as sops recipient"
git push

# In this nix flake repo
just update-secrets
```

### 6. Update `sops.age.sshKeyPaths` on the host

In the host's NixOS configuration:

```nix
sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
```

Drop any old paths (`/home/<user>/...`, `/root/id_infrastructure`) once the new path is proven working. Keep both during the transition for safety — sops tries all available identities and uses the first that decrypts.

Deploy: `colmena apply --on <host> --impure`. Look for `Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint <recipient>` in the activation log.

## Procedure: back up the host's identity to nix-secrets

So a rebuilt host can use the same recipient and skip the re-keying dance:

```bash
cd /path/to/nix-secrets
ssh <host> 'sudo cat /etc/ssh/ssh_host_ed25519_key' > /tmp/hostkey
{ echo "data: |"; sed 's/^/  /' /tmp/hostkey; } > secrets/host/<host>/ssh_host_ed25519_key.sops
shred -u /tmp/hostkey 2>/dev/null || rm -f /tmp/hostkey
sops --encrypt --in-place --input-type yaml --output-type yaml \
  secrets/host/<host>/ssh_host_ed25519_key.sops
```

Then add a path mapping in `secrets/default.nix`:

```nix
<host> = {
  ...
  ssh-host-ed25519-key = ./host/<host>/ssh_host_ed25519_key.sops;
};
```

The entry isn't consumed by any Nix module — it's documentation + a recovery artifact. Future-you decrypts it manually before the first `colmena apply` on a rebuilt host.

## Recovery: rotating a host's recipient (key lost)

If the host's private key is gone and you don't have the backup blob:

1. On the rebuilt host, let NixOS generate fresh host keys at first boot.
2. From any workstation, run steps 1–6 above with the new pub key.
3. Step 4 (`sops updatekeys`) succeeds because the workstation key is still a recipient on every file.

The workstation key (`~/.ssh/id_ed25519`) is the root of trust. Don't lose THAT — it's the only thing standing between you and a from-scratch re-encryption of every secret.
