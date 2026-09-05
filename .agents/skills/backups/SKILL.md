---
name: backups
description: Configure and verify Borg backups for this nix flake project. Use when adding, changing, auditing, or troubleshooting backup schedules on gnomeregan, including remote SSH/rsync-staged backups from other hosts.
---

# Project Backups

Use this skill when the user asks to add, change, verify, or troubleshoot backups.

## Key files

- Main backup module: `modules/services/borg-backup.nix`
- Backup host: `gnomeregan`
- Host wiring: `colmena/hosts/gnomeregan.nix`
- Service state usually lives in the service module: `modules/services/<service>.nix`
- Hetzner root SSH authorization: `colmena/hetzner-common/default.nix`
- gnomeregan Home Manager secrets: `modules/home-manager/features/secrets.nix`

## Discovery checklist

1. Run `graphify query "<service> backup gnomeregan borg directories schedule"` if `graphify-out/graph.json` exists.
2. Read `modules/services/borg-backup.nix` before editing.
3. Read the target service module, e.g. `modules/services/hermes.nix`, and identify persistent state from:
   - container bind mounts / volumes,
   - `systemd.tmpfiles.rules`, `StateDirectory`, or explicit data directories,
   - sync scripts or database paths.
4. Back up service state directories, not SOPS-managed secrets. Secrets should be recoverable from `nix-secrets` unless the user explicitly asks for a filesystem secret backup.
5. State the verified directories before adding the schedule.

## Backup model on gnomeregan

`modules/services/borg-backup.nix` supports two kinds of jobs:

- Storage Box CIFS jobs:
  - names live in `dailyStorageNames`, `weeklyNames`, or `monthlyNames`,
  - Storage Box sub-account mappings live in `storages`,
  - optional path narrowing lives in `storagePaths`,
  - optional borg excludes live in `storageExcludes`.
- Remote SSH/rsync-staged jobs:
  - names live in `dailyRemoteNames` (or another remote frequency list if added),
  - source definitions live in `remoteBackups`,
  - data is rsynced into `/var/lib/backup-staging/<name>` first,
  - borg snapshots the staging directory into `/mnt/hetzner-backup/borg-repos/<name>`.

When adding a new remote backup, prefer the existing `mkRemoteBorgJob` pattern rather than adding an ad-hoc systemd service.

## Remote SSH requirements

Before claiming a remote backup will work, verify both sides:

1. gnomeregan has a usable private key. Current remote jobs use:
   - `/home/fdrake/.ssh/id_ansible`
   - provided by Home Manager SOPS secret `ssh-id-ansible`.
2. the source host authorizes the matching public key for the backup user.
   - Hetzner servers authorize root keys in `colmena/hetzner-common/default.nix`.
3. the source SSH port and user match the host config.
   - Hetzner app servers usually use root on port `2222`.
4. live-test from gnomeregan when the host is reachable:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 gnomeregan.internal.freddrake.com 'bash -s' <<'REMOTE'
sudo ssh -i /home/fdrake/.ssh/id_ansible -p 2222 \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile=/tmp/gnomeregan-backup-known_hosts \
  -o IdentitiesOnly=yes \
  root@<source-ip> 'hostname; test -r <backup-path> && echo backup-path-readable'
REMOTE
```

Use the actual source IP, port, user, and path from the host/service modules.

## Editing checklist

1. Add the backup name to the appropriate frequency list.
2. For Storage Box jobs, add/update `storages`, `storagePaths`, or `storageExcludes` as needed.
3. For remote jobs, add a `remoteBackups.<name>` entry with:
   - `host`, `port`, `user`, `paths`, and `identityFile`,
   - comments documenting why those paths are the complete service state.
4. Ensure the job is included in `allNames` so backup status includes it.
5. Keep descriptions accurate, e.g. daily wrapper description should include new daily jobs.

## Validation

Run before reporting success:

```bash
nix run nixpkgs#alejandra -- modules/services/borg-backup.nix
nix-instantiate --parse modules/services/borg-backup.nix >/dev/null
nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: nodes.gnomeregan.config.services.borgbackup.jobs."hetzner-<name>".paths'
nix run nixpkgs#colmena -- --impure eval -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.borg-backup-daily.script'
git diff --check
graphify update .
```

If creating new files, `git add` them so the git-backed flake can see them when referenced.

## Deployment note

Do not deploy unless asked. If asked to deploy, follow the infrastructure skill's Colmena guidance: use the project workflow/subagent expectations rather than running a noisy ad-hoc fleet deploy in the main context.
