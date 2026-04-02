---
name: provision-nixos-server
description: |
  Provision new NixOS servers on Hetzner for this nix flake project. Guides through the complete workflow: server creation, SSH setup, Colmena configuration (init/full pattern), and application deployment with nginx proxy, PostgreSQL, and container images.

  Use when: (1) Setting up a new Hetzner server, (2) Setting up a new NixOS host with Colmena, (3) Deploying applications with nginx SSL proxy and/or PostgreSQL database, (4) Adding new container images to the repository.
---

# Provision NixOS Server

## Workflow Overview

1. Gather requirements from user
2. Create Hetzner server and install NixOS
3. Set up SSH access
4. Create Colmena init configuration
5. Deploy init config
6. Copy infrastructure key for SOPS
7. Configure application (if applicable)
8. Deploy full configuration

## Step 1: Gather Requirements

Ask user for:
- **Hostname**: Server name (e.g., `ironforge`)
- **Hetzner plan**: Server type/plan
- **Application**: What will run on this server

Verify soft-secrets exist for the new host (`host.<hostname>.admin_ip_address`, etc.) or ask user to create them.

## Step 2: Create Hetzner Server

Create a Hetzner server and install NixOS via nixos-infect or the Hetzner NixOS image. Ensure SSH access is configured with the user's public key.

## Step 3: Set Up SSH Access

Ensure root SSH access works:
```bash
ssh root@<SERVER_IP> "echo 'SSH works'"
```

Add the authorized keys if needed:
```bash
ssh root@<SERVER_IP> "mkdir -p ~/.ssh && curl -s https://github.com/fred-drake.keys > ~/.ssh/authorized_keys"
```

## Step 4: Create Colmena Init Configuration

Create these files:

1. `mkdir -p modules/nixos/host/<hostname>`
2. Create `modules/nixos/host/<hostname>/configuration.nix`
3. Create `colmena/hosts/<hostname>.nix`
4. Update `colmena/default.nix` with imports

**Initial deploy config:** Use server IP and `root` user:
```nix
deployment = {
  buildOnTarget = true;
  targetHost = "<SERVER_IP>";
  targetUser = "root";
};
```

Stage files and build:
```bash
git add colmena/hosts/<hostname>.nix modules/nixos/host/<hostname>/ colmena/default.nix
colmena build --impure --on <hostname>-init
```

## Step 5: Deploy Init

```bash
colmena apply --impure --on <hostname>-init
```

If the network configuration changes the IP, the command may hang. Kill it and update the deployment target to the new IP, then re-deploy.

## Step 6: Copy Infrastructure Key

Required for SOPS secret decryption:
```bash
scp ~/.ssh/id_infrastructure root@<SERVER_IP>:~/id_infrastructure
ssh root@<SERVER_IP> "chmod 600 ~/id_infrastructure"
```

**Age public key** (for .sops.yaml): `age1rnarwmx5yqfhr3hxvnnw2rxg3xytjea7dhtg00h72t26dn6csdxqvsryg5`

If secrets fail to decrypt, user needs to add this key to `.sops.yaml` and run `sops updatekeys` on the secret files.

## Step 7: Configure Application

### Add Container Images

1. Edit `apps/fetcher/containers.toml`
2. Run `just update-container-digests`
3. Stage: `git add apps/fetcher/containers.toml apps/fetcher/containers-sha.nix`

### Create Application Config

Create `apps/<appname>.nix` with:
- Nginx proxy with SSL (if web-facing)
- PostgreSQL container (if database needed)
- Application container(s)
- tmpfiles rules for data directories

### Create Secrets Config

Create `modules/secrets/<hostname>.nix` referencing SOPS files.

User must create SOPS files in secrets repo with:
- `postgresql-env.sops` (POSTGRES_PASSWORD, POSTGRES_USER, POSTGRES_DB)
- `<appname>-env.sops` (app-specific secrets)

### Update Colmena Full Config

In `colmena/hosts/<hostname>.nix`, add to full configuration imports:
```nix
../../modules/secrets/<hostname>.nix
../../apps/<appname>.nix
```

## Step 8: Deploy Full Configuration

```bash
just update-secrets  # Get latest secrets
git add <all-new-files>
colmena apply --impure --on <hostname>
```

## Common Issues

**SOPS decrypt fails:** Age key not in .sops.yaml - user must add key and re-encrypt

**Nginx duplicate directive:** Don't add `proxy_http_version` when using `proxyWebsockets = true`

**PostgreSQL 18 fails:** Mount at `/var/lib/postgresql` not `/var/lib/postgresql/data`

**Container can't reach postgres:** Use `0.0.0.0:5432:5432` for port binding, `host.containers.internal` in connection string
