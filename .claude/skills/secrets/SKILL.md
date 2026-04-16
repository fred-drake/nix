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
