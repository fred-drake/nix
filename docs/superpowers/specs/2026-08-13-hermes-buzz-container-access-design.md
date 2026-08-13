# Hermes-to-Buzz container access design

## Goal

Permit the existing Hermes container on Orgrimmar to reach the private Buzz relay through its canonical HTTPS/WebSocket hostname, while retaining network and application authentication boundaries.

## Design

Add `allow 10.88.0.0/16;` to the main `buzz.internal.freddrake.com` nginx vhost before `deny all`. This is Orgrimmar's default rootful Podman bridge subnet and includes the observed Hermes source address `10.88.0.76`.

Do not add this subnet to the exact `/pair` location. Pairing remains reachable only from the existing Hetzner private and Tailscale ranges.

The network allowlist is not the authorization boundary for relay operations. Buzz continues to require relay membership and NIP authentication. No API token, NIP-OA fallback, unmanaged nginx edit, NAT rule, or public exposure is introduced.

## Validation

After an Orgrimmar-only deployment:

- the main Buzz health endpoint succeeds from the Hermes container;
- `/pair` remains denied from the Hermes container;
- an unauthenticated protected relay request remains rejected by the relay;
- existing Tailscale/private clients remain healthy;
- nginx, Buzz, and Hermes remain active;
- no other host is changed.

## Rollback

Revert the single allowlist line and redeploy Orgrimmar. No persistent Buzz or Hermes data changes are involved.
