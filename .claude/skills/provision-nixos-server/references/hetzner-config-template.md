# Hetzner Server: NixOS Configuration Template

File: `modules/nixos/host/<host>/configuration.nix`

Two flavors based on what the server does:

## Basic Server (no containers, no app proxy)

For hosts like `headscale` that don't run podman containers.

```nix
_: {
  networking = {
    hostName = "<host>";
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "<internal-ip>";  # e.g. 10.1.1.5
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
```

That's the entire file. The base hardware/network setup, default
gateway routing, ssh keys, and firewall come from
`colmena/hetzner-common/` via `modules/services/hetzner-server.nix`.

## App Server (podman + nginx + Let's Encrypt + container disk)

For hosts like `orgrimmar`, `ironforge`, `stormwind` that run
containerized services.

```nix
_: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "<uuid-from-blkid>";
    })
  ];

  networking = {
    hostName = "<host>";
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "<internal-ip>";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
```

The `hetzner-app-server.nix` module bundles:

- `podman-server.nix` — podman + dockerCompat + DNS-aware default network
- `nginx-acme-proxy.nix` — nginx + ACME (DNS-01 via Cloudflare) + the
  `cloudflare-api-key` sops secret
- SSH port shifted to 2222 (`services.openssh.ports = [2222]`)
- Firewall opens 2222 (replaces 22)
- Filesystem mount of the container data disk at `/var/lib/containers`

## Finding the container disk UUID

After attaching a second block device in the Hetzner console, ssh into
the box and run:

```bash
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT
# or
blkid
```

You want the UUID of the *unmounted* ext4 disk (not `/dev/sda1` which
is the root filesystem). If the disk isn't yet formatted, format it
first:

```bash
mkfs.ext4 /dev/sdb
blkid /dev/sdb  # capture the UUID this prints
```

## Why `enp7s0` and `/32`?

Hetzner private-network NICs typically enumerate as `enp7s0` on their
NixOS image. The `/32` prefix is intentional — `colmena/hetzner-common/
networking.nix` adds an explicit route to the gateway address
(`10.1.0.1` for normal servers, via the headscale gateway), so the
host doesn't need a broad subnet.

If `ip link` on your fresh box shows a different name (e.g. `eth0`,
`ens3`), update the interface name accordingly. The rest of the config
is unchanged.

## Interaction with hasMonitoring

If `_<host>.my.hasMonitoring = true` (default for servers in this repo),
the dendritic feature `modules/features/prometheus-node-exporter.nix`
activates and tries to read
`config.soft-secrets.host.<host>.admin_ip_address`. This MUST exist
in nix-secrets or evaluation will fail.

Two safe orderings:

1. **soft-secrets first** — add `host.<host>.admin_ip_address` to
   nix-secrets, commit, pin, *then* deploy with `hasMonitoring = true`.
2. **deploy first** — set `hasMonitoring = false` for the first
   deploy. After adding the soft-secret, flip to `true` and redeploy.

The skill flow assumes option 1; see SKILL.md Step 1.
