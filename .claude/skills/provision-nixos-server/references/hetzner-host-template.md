# Hetzner Server: Colmena Host Configuration Template

For Hetzner cloud/dedicated servers. The base server profile is shared
across hosts via `modules/services/hetzner-server.nix` (which pulls in
`colmena/hetzner-common/`).

Two flavors exist:

- **Basic server** (e.g. `headscale`) — bare OS, SSH on port 22, suitable
  for hosts that aren't running containerized apps.
- **App server** (e.g. `orgrimmar`, `ironforge`, `stormwind`) — adds
  podman + nginx + Let's Encrypt + a dedicated container data disk.
  SSH moves to port **2222**.

Both flavors use the same `_<host>` / `<host>-init` / `<host>` triplet.
The triplet exists so a single host config can be deployed two ways:

- `colmena apply --on <host>-init` — Colmena dials SSH on the *current*
  port (22 for a freshly-imaged box) but pushes a config that may switch
  SSH to 2222 on activation. Used once, when first provisioning.
- `colmena apply --on <host>` — Colmena dials the *steady-state* SSH
  port (2222 for app servers, 22 for basic). Used for all subsequent
  deploys.

## File: colmena/hosts/<host>.nix

```nix
{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for <host>
  _<host> = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
    };

    # If the host needs to resolve internal hostnames (e.g. another
    # internal-tailnet service), add them here. Only required when
    # something on this host pulls from gitea or talks to a service
    # by hostname that isn't in public DNS.
    #
    # networking.extraHosts = ''
    #   10.1.1.4 gitea.${soft-secrets.networking.domain}
    # '';

    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
        ../../modules/services/hetzner-server.nix
        ../../modules/nixos/host/<host>/configuration.nix
        nixpkgsVersion
      ]
      ++ deferredNixosModules;

    my = {
      hostName = "<host>";
      isServer = true;
      hasMonitoring = true;  # set false on first deploy if soft-secrets.host.<host>.admin_ip_address isn't in nix-secrets yet
    };

    deployment = {
      buildOnTarget = true;
      targetHost = "<internal-ip>";  # e.g. 10.1.1.5
      targetUser = "root";
      # For APP SERVER (configuration.nix imports hetzner-app-server.nix):
      # targetPort = 2222;
      # For BASIC SERVER (configuration.nix imports only hetzner-server.nix):
      # leave targetPort unset (defaults to 22)
    };
  };

  # Init deploy — used the FIRST time only, to dial in on whatever port
  # the freshly-imaged box is currently using (typically 22). For an
  # app server whose full config moves SSH to 2222, this override is
  # what makes the initial deploy reachable.
  "<host>-init" = {
    imports = [
      self.colmena._<host>
    ];
    # Only needed when _<host>.deployment.targetPort = 2222:
    # deployment.targetPort = nixpkgs-stable.lib.mkForce 22;
  };

  # Full configuration — imports the service modules this host runs.
  "<host>" = {
    imports = [
      self.colmena._<host>
      # ../../modules/services/<service>.nix
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
```

## Updates to colmena/default.nix

Four edits in the existing file:

1. Function arg + import (near the top, with the other host imports):
```nix
<host> = import ./hosts/<host>.nix {inherit self nixpkgs-stable secrets sops-nix nixosOptionsModule deferredNixosModules;};
```

2. `inherit` line in the base-config section:
```nix
inherit (<host>) _<host>;
```

3. Init configuration line:
```nix
"<host>-init" = <host>."<host>-init";
```

4. Full configuration line:
```nix
"<host>" = <host>."<host>";
```

## SSH port transition explained

When you first ssh-infect a Hetzner box, sshd listens on port 22. If the
host config imports `hetzner-app-server.nix`, that module sets
`services.openssh.ports = [2222]` and `networking.firewall.allowedTCPPorts = [2222]`.
So at the moment Colmena activates the new system, sshd reloads on 2222
and (if you didn't add an `allowedTCPPorts = [22]` override) port 22
starts refusing connections.

The init/full split handles this:

| Stage | Box's current sshd port | Colmena targetPort | Mechanism |
|---|---|---|---|
| Before first deploy | 22 (Hetzner default) | — | — |
| `colmena apply --on <host>-init` | 22 → 2222 during activation | 22 | `<host>-init` overrides targetPort to 22 |
| Subsequent `colmena apply --on <host>` | 2222 | 2222 | inherits from `_<host>` |

**For a basic server** (no port change), the init override is unnecessary
and you can leave `targetPort` unset everywhere (defaults to 22).

## App-server data disk

`hetzner-app-server.nix` expects a separate ext4-formatted block device
mounted at `/var/lib/containers` (where podman stores image layers, container
storage, and volume mounts). The disk UUID is plumbed in via the host
config — see `hetzner-config-template.md`.

If the box doesn't have a second disk attached yet, attach one through
the Hetzner console first and find its UUID with `blkid` after rebooting.
