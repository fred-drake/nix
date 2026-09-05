# Gnomeregan

Personal LAN NixOS box (home Wi-Fi, x86_64). Hosts always-on automation that used to live on the now-sunsetted mac-studio: borg backups against the Hetzner storage box, the glance dashboard, and personal Claude-driven jobs (`process-daily`, `archive-email`) under fdrake's systemd-user timers with linger enabled.

It's deliberately different from the Hetzner servers, so don't assume the hetzner-common pattern applies here.

## Why it's unusual

- **Tracks `nixpkgs-unstable`**, set per-host in `colmena/default.nix` via `meta.nodeNixpkgs.gnomeregan`. Other servers are on stable. Unstable is required because the workstation home-manager feature stack references unstable-only attrs (`pkgs.prettier`, `lndir`, etc.). Splitting modules-on-stable + pkgs-on-unstable hits real boot issues (`kbd.gzip` mismatch in `console.nix`); WSL hosts (anton) sidestep this because their config skips the affected modules.
- **Runs the full workstation HM stack for `fdrake`** — claude-code, dev-tools, the whole `secrets.nix` feature with ~84 sops secrets, etc. Wired into colmena/hosts/gnomeregan.nix mirroring anton's pattern (`home-manager.nixosModules.home-manager` + `mkHomeManager`).
- **fdrake has `users.users.fdrake.linger = true`** so systemd user units start at boot before any interactive login. Required for process-daily / archive-email to fire on schedule.
- **Login shell is `fish`** (`shell = pkgs.fish; ignoreShellProgramCheck = true;` + `environment.shells = [pkgs.fish];`), matching wsl-common pattern.
- **`programs.nix-ld.enable = true`** so uvx-launched Python interpreters (workspace-mcp dependency for archive-email) can run despite being dynamically linked against a generic glibc.

## SOPS identity model

Gnomeregan uses **its own SSH host key** as its age identity:

```nix
sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
```

The host's age recipient (`age1kdu824t8sf07kf94zuakx38dk835fknftpdpsqjv9fjamzxwnvasryg2vm`) is registered as a third recipient on every secret gnomeregan reads in `nix-secrets/.sops.yaml`:

- `secrets/host/gnomeregan/.*` — borg-backup, wireless-env
- `secrets/host/glance/.*` — glance.env
- `secrets/host/ironforge/.*-storage\.sops\.yaml` — CIFS creds for borg mounts

This was a deliberate choice over the `id_infrastructure` pattern hetzner hosts use, because:

1. `/etc/ssh/ssh_host_ed25519_key` is on `/` → accessible from stage 1 (initrd-systemd), which is required by NixOS 26.11+. Hetzner's `/root/id_infrastructure` only works because they don't run workstation HM on the same box.
2. The HM `secrets` feature deploys `~/.ssh/id_infrastructure` as a sops-managed symlink to a path that only exists after HM activates — chicken-and-egg if NixOS-level setupSecrets tries to use that path.

The workstation key (`~/.ssh/id_ed25519`) is also present on gnomeregan (copied from a workstation manually) and is what HM-level sops uses to decrypt the ~84 workstation HM secrets.

## Wireless PSK

`/etc/wireless.env` was used out-of-band initially; it's now a sops secret at `secrets/host/gnomeregan/wireless-env.sops`, deployed to `/run/secrets/wireless-env` owned by the `wpa_supplicant` user (the unit drops privileges + runs in a tight namespace on unstable, so root-owned files break it).

## Disaster recovery: rebuilding gnomeregan from scratch

The host's SSH ed25519 private key is backed up in nix-secrets at `secrets/host/gnomeregan/ssh_host_ed25519_key.sops`. Restoring it lets every existing encrypted secret keep working — no re-keying required.

From a fresh NixOS install on the box, before the first `colmena apply --on gnomeregan`:

```bash
# Run on gnomeregan as root, after rsyncing nix-secrets to the box.
# (Or run on a workstation, then scp the decrypted file across.)
sops --decrypt secrets/host/gnomeregan/ssh_host_ed25519_key.sops \
  | install -m 0600 /dev/stdin /etc/ssh/ssh_host_ed25519_key
ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key \
  > /etc/ssh/ssh_host_ed25519_key.pub
```

You'll also need:

- The workstation `id_ed25519` private key at `/home/fdrake/.ssh/id_ed25519` (0600) — for HM-level sops to decrypt the workstation secrets. Same key as on every other workstation.
- `/etc/wireless.env` is NOT needed; the wireless PSK is now a sops secret.
- PKM-Personal cloned at `~/Source/gitea.<domain>/fdrake/PKM-Personal` — process-daily and archive-email both cd there. Manual clone after first deploy.
- One interactive `claude` invocation as fdrake to establish the auth token.
- The workspace-mcp OAuth tokens in `~/.google_workspace_mcp/credentials/fred.drake@gmail.com.json` (scp from another machine that has them).

## Recovery if the host key is genuinely lost

The fallback (if the backup blob in nix-secrets is also somehow gone):

1. Let NixOS generate fresh host keys on first boot.
2. `ssh-to-age` the new `/etc/ssh/ssh_host_ed25519_key.pub` to get a new age recipient.
3. Update `nix-secrets/.sops.yaml`: replace gnomeregan's recipient in the four rule blocks where it appears.
4. From a workstation: `sops updatekeys` on every affected file (workstation key authenticates).
5. Commit + push nix-secrets, `just update-secrets` in the nix repo, deploy.

Equivalent to the original migration — works as long as you still have the workstation key.

## Troubleshooting: process-daily / archive-email job failures

Both jobs run `claude -p ...` as fdrake under systemd-user timers, logging
stream-json to `~/.local/state/<job>.{log,err}`. The timers fire reliably; when
a job "stops working" the failure is almost always inside the `claude`
invocation, not the timer or the google-workspace MCP.

Triage (SSH in as fdrake; login shell is **fish**, so wrap loops/`VAR=` in
`bash -c`):

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user list-timers archive-email.timer          # is it scheduled?
systemctl --user status archive-email.service             # last run result
# Per-run final outcome (is_error + the actual error text):
grep '"type":"result"' ~/.local/state/archive-email.log \
  | tail -3 | jq -r '[.subtype,(.is_error|tostring),(.result//"")]|@tsv'
```

A run that dies in **~3s with `is_error:true`** and num_turns 1 never reached
the email work — `claude` itself failed on turn 1. A healthy run takes
**3–4 min** and ends `Finished` (Result=success).

### Most common cause: expired Claude Max OAuth token

`API Error: 401 Invalid authentication credentials` means the claude.ai **Max
OAuth token** in `~/.claude/.credentials.json` expired and auto-refresh failed.
This happens when the same account re-authenticates Claude Code on another
machine (or a session is revoked) — that invalidates gnomeregan's token. Check
without printing secrets:

```bash
jq '{subscriptionType, expiresAt: (.claudeAiOauth.expiresAt/1000|todate)}' \
  ~/.claude/.credentials.json
```

Note: simply launching `claude` interactively does **not** prompt for re-login
when a stale credential is present — it looks logged in, and the 401 only
surfaces on the first real API call. So "I opened claude and it didn't ask me
to log in" does not mean auth is healthy.

**Fix** (interactive — OAuth can't be scripted): in an SSH session as fdrake,
run `claude`, then `/login`, pick the Max account, and complete the browser/code
flow (headless box prints a URL + asks for the pasted code). Then verify:

```bash
claude --model sonnet -p "say OK"                 # expect "OK", exit 0
systemctl --user start archive-email.service       # real run, expect "Finished"
```

The timer needs no changes; it picks up the new credential on the next tick.

### SSH host-key gotcha while debugging

If your workstation can't even SSH in (`Host key verification failed` after the
known_hosts entry was cleared), the key gnomeregan presents is genuine iff it
converts to the recorded age recipient
(`age1kdu824t8sf07kf94zuakx38dk835fknftpdpsqjv9fjamzxwnvasryg2vm`):

```bash
ssh-keyscan -t ed25519 192.168.8.2 | grep -o 'ssh-ed25519 .*' \
  | nix run nixpkgs#ssh-to-age      # must equal the recipient above
```

Match → safe to re-add to known_hosts (key did not rotate). Mismatch → the host
key actually changed, which would also break its sops decryption (see SOPS
identity model above).

## File touch-points

| Concern | File |
|---------|------|
| Host config | `modules/nixos/host/gnomeregan/configuration.nix` |
| Colmena wiring (unstable pin, HM) | `colmena/hosts/gnomeregan.nix`, `colmena/default.nix` |
| Per-host HM (systemd user services) | `modules/home-manager/host/gnomeregan.nix` |
| Backups | `modules/services/borg-backup.nix` |
| Dashboard | `modules/services/glance-dashboard.nix` |
| Sops rules for gnomeregan | `nix-secrets/.sops.yaml` (3-recipient rules) |
| Host key backup | `nix-secrets/secrets/host/gnomeregan/ssh_host_ed25519_key.sops` |
