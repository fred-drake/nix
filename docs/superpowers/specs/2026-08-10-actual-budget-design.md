# Actual Budget on Orgrimmar — Design

## Goal

Run the official Actual Budget sync server on Orgrimmar as a declaratively managed Podman container, available only to Tailnet/internal clients and protected by daily Borg backups.

## Scope

- Use the official `actualbudget/actual-server` image, pinned by digest through the repository's container-image fetcher.
- Add an `actual.nix` NixOS service module and import it in Orgrimmar's Colmena configuration.
- Persist Actual state at `/var/actual` on Orgrimmar; mount it as `/data` in the container.
- Bind the container only to `127.0.0.1:5006`.
- Publish `https://actual.internal.freddrake.com` through the existing nginx ACME proxy. Restrict that vhost to `10.1.0.0/16` and `100.64.0.0/10`, matching the private Buzz service.
- Keep Actual's default password authentication. The administrator sets the initial password in Actual's first-run web flow; no password is placed in Nix or SOPS.
- Add `/var/actual` as a daily remote Borg backup from Orgrimmar to gnomeregan, alongside the existing Hermes remote backup.

## Architecture

`virtualisation.oci-containers` uses the Podman backend to run a single `actual` container. It uses the repository's digest-pinned image map and starts automatically. A tmpfiles rule creates the persistent host directory. The container maps it to `/data`, which is Actual's documented default data directory; it contains the server account database, password hash, session state, and budget files.

The service does not expose its port on Orgrimmar's network interface. The shared nginx proxy terminates TLS and forwards the internal hostname to the loopback listener. The vhost-level allow rules ensure that even a request reaching the public server address is denied unless it originates on the private network or Tailnet.

The gnomeregan Borg module adds an `actual` remote backup definition for Orgrimmar's `/var/actual`. It becomes part of the daily sequential backup wrapper and receives the existing retention policy: seven daily, four weekly, and six monthly archives.

## Image and update policy

The image is recorded in `apps/fetcher/containers.toml` and resolved into `apps/fetcher/containers-sha.nix` by the repository's existing fetcher. Nix references the resulting linux/amd64 digest, so deployment is reproducible and does not silently pull an unreviewed `latest` image. Updating Actual means updating that pin using the existing container update workflow.

## Error handling and operations

Podman restarts the container through the generated systemd unit. Nginx exposes the standard proxied application endpoint. If the service is unavailable, operators inspect `podman-actual.service` and its container logs. If the backup run fails, the existing Borg wrapper records the failure while continuing the remaining backup jobs; freshness status reports `actual` independently.

## Verification

The implementation will evaluate the affected Nix configuration, confirm the generated service has a loopback-only port mapping and persistent `/data` mount, and check the nginx/private-network restrictions and Borg remote-job membership. After deployment, it will verify the HTTPS endpoint from a Tailnet client, the container's health, and successful inclusion of Actual data in a Borg archive.
