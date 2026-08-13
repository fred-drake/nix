# Buzz pairing relay design

## Goal

Enable Buzz mobile pairing at the existing private relay hostname without changing the main relay or exposing a new public endpoint.

## Design

Run `buzz-pair-relay` from the existing pinned `ghcr.io/block/buzz:main` image as a second Podman container. Bind it to a dedicated loopback-only port on orgrimmar.

Add an exact nginx `/pair` WebSocket location for `buzz.internal.freddrake.com` that proxies to this sidecar. Retain the existing private-network access policy. All other paths continue to proxy to the main `buzz-relay` at port 3003.

The main relay advertises the reachable pairing endpoint via `BUZZ_PAIRING_RELAY_URL`, using the existing `wss://buzz.internal.freddrake.com/pair` URL.

## Validation

- Nix evaluation/build for orgrimmar succeeds.
- Deployment targets only orgrimmar.
- Both main and pairing containers are active.
- The `/pair` route reaches the pairing relay rather than returning the main relay's 404.
- The user retries mobile pairing for end-to-end confirmation.
