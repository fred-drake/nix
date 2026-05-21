---
name: secrets
description: |
  Add, remove, or modify SOPS secrets used by workstation home-manager and NixOS server services.
  Use when: (1) Adding a new secret for an MCP server, service, or tool, (2) Removing a deprecated
  secret, (3) Wiring a secret into a sops.template (e.g. MCP config with API key), (4) Understanding
  how secrets flow from the external nix-secrets repo into this flake.
---

# Secrets Management

## Architecture Overview

Secrets are managed with **sops-nix** and split across two repositories:

1. **`nix-secrets`** (external, private) — the encrypted YAML files and the
   NixOS module that exposes `config.secrets.*` option paths. This repo is
   a flake input named `secrets`. The user manages this repo separately.
2. **This flake** — declares which secrets to decrypt (`sops.secrets`),
   where to place them, and how to reference them in templates
   (`sops.templates`).

You do NOT have access to the nix-secrets repo. When the user says "secrets
are in place" or "I've updated the secrets repo", trust that the
`config.secrets.*` path they specify exists.

## Recipient Model

Every encrypted secret in `nix-secrets` is encrypted to one or more **age recipients**, selected by path-regex rules in `nix-secrets/.sops.yaml`. There are three classes of recipients currently in use:

| Recipient | Derived from | Used by |
|-----------|--------------|---------|
| `workstation` | The user's personal `id_ed25519` SSH key (same key on every workstation) | All workstation secrets, plus everything in the catch-all default rule |
| `infrastructure` | A shared age key (`id_infrastructure`) deployed to Hetzner servers as `/root/id_infrastructure` | Hetzner host secrets that hetzner-common boxes need at activation |
| **per-host** (e.g. `gnomeregan`) | The host's own `/etc/ssh/ssh_host_ed25519_key.pub`, converted with `ssh-to-age` | Secrets read by hosts that can't rely on the workstation or infrastructure keys at stage 1 |

The catch-all rule (`secrets/.*`) encrypts to **workstation only**. Specific path-regex rules above it can add `infrastructure` and/or per-host recipients.

### When to add a per-host recipient

Default to two recipients (workstation + infrastructure) for any server secret. Add a per-host recipient when:

- The server runs the workstation home-manager stack (so `~/.ssh/id_infrastructure` becomes a HM-managed symlink, dangling until HM activates — too late for stage-1 setupSecrets).
- The server can't reach `/home/<user>/.ssh/` from stage 1 (e.g., the user's home is on a separate mount, or the user doesn't exist yet at that point in boot).
- You want a host that can rotate its own identity without affecting any other host.

`gnomeregan` is the only host in this setup that needs this today. See `references/per-host-recipients.md` for the full procedure (deriving the recipient, updating `.sops.yaml`, re-encrypting existing files, and the sops 3.12 SSH→age conversion quirk).

## Two Contexts for Secrets

### Workstation secrets (home-manager)

**File:** `modules/home-manager/features/secrets.nix`

Used on macOS/Linux desktops. Secrets are decrypted by a sops-nix
LaunchAgent (macOS) or systemd user service (Linux) into
`$XDG_RUNTIME_DIR/secrets/` or equivalent.

**sopsFile paths** use `config.secrets.workstation.<name>`:

```nix
sops.secrets = {
  my-secret = {
    sopsFile = config.secrets.workstation.my-service;
    mode = "0400";
    key = "api-key";  # key inside the YAML file
  };
};
```

Common patterns:
- `key = "data"` — the entire file content is the secret (env files, JSON)
- `key = "api-key"` / `key = "token"` — a specific field in the YAML
- `path = "${home}/...";` — optional, symlinks the decrypted secret to
  a specific location (e.g. `~/.ssh/id_rsa`, `~/.docker/config.json`)

### Server secrets (NixOS services)

**File:** `modules/services/<service>.nix`

Used on NixOS servers deployed with Colmena. Secrets decrypt into
`/run/secrets/`.

**sopsFile paths** use `config.secrets.host.<service>.<secret-name>`:

```nix
sops.secrets = {
  myservice-env = {
    sopsFile = config.secrets.host.myservice.env;
    mode = "0400";
    key = "data";
  };
};
```

These are typically referenced via `config.sops.secrets.<name>.path`
in container `environmentFiles` or service config.

## Using Secrets in SOPS Templates

SOPS templates render secret values into config files at activation
time. Used heavily for MCP server configs in
`modules/home-manager/features/claude-code.nix`.

**Reference a secret value with** `config.sops.placeholder.<secret-name>`:

```nix
sops.templates = {
  mcp-myservice = {
    mode = "0400";
    path = "${home}/mcp/myservice.json";
    content = builtins.toJSON {
      mcpServers = {
        myservice = {
          command = "some-command";
          env = {
            API_KEY = config.sops.placeholder.my-api-key;
          };
        };
      };
    };
  };
};
```

The placeholder name must match a secret declared in `sops.secrets`.

## Step-by-Step: Adding a New Secret

1. **User updates nix-secrets repo** with the encrypted YAML file and
   registers it as a `config.secrets.workstation.<name>` option. Ask
   the user to do this if not already done.

2. **Declare the secret** in `modules/home-manager/features/secrets.nix`
   under `sops.secrets`:
   ```nix
   my-new-secret = {
     sopsFile = config.secrets.workstation.<name>;
     mode = "0400";
     key = "<yaml-key>";
   };
   ```

3. **Reference the secret** where needed:
   - In a sops template: `config.sops.placeholder.my-new-secret`
   - As a file path: `config.sops.secrets.my-new-secret.path`
   - In a container env file: add path to `environmentFiles`

4. **Run `just switch`** to activate.

## Step-by-Step: Removing a Secret

1. Remove the `sops.secrets.<name>` entry from `secrets.nix`.
2. Remove any references to `config.sops.placeholder.<name>` or
   `config.sops.secrets.<name>.path` in other modules.
3. Run `just switch`.
4. Optionally ask the user to clean up the nix-secrets repo.

## Key Files

| Purpose | Path |
|---------|------|
| Workstation secret declarations | `modules/home-manager/features/secrets.nix` |
| MCP server configs (sops templates) | `modules/home-manager/features/claude-code.nix` |
| Server service secrets | `modules/services/<service>.nix` |
| Secrets flake input | `flake.nix` (input named `secrets`) |

## Decrypting / Re-keying nix-secrets Locally

If you need to read or `sops updatekeys` an encrypted file (e.g. to add a recipient), you'll need sops to be able to decrypt it locally. sops 3.12+ removed direct SSH-key support — you have to convert your SSH key to an age identity first:

```bash
ssh-to-age -i ~/.ssh/id_ed25519 -private-key > /tmp/workstation-age.key
export SOPS_AGE_KEY_FILE=/tmp/workstation-age.key
```

Then `sops --decrypt`, `sops updatekeys`, etc. work as expected. Some files use a `.sops` extension but are YAML internally — pass `--input-type yaml --output-type yaml` explicitly if sops can't infer the format.

See `references/per-host-recipients.md` for the full re-keying flow when adding or rotating a host recipient.

## Important Notes

- The `config.secrets.*` option paths are defined in the external
  nix-secrets flake, not in this repo. Do not try to create them here.
- On macOS, sops-nix runs as a LaunchAgent. After `just switch`,
  secrets are re-rendered automatically.
- Secret names in `sops.secrets` must be unique across the entire
  home-manager config. Use descriptive prefixed names
  (e.g. `resume-api-key`, `gitea-storage-password`).
- Never log, echo, or embed raw secret values. Always use
  `sops.placeholder` or `sops.secrets.*.path` indirection.
