# Gnomeregan Tailscale Design

## Goal
Connect gnomeregan to the existing Tailscale SaaS tailnet for remote access.

## Design
Import the repository's existing `modules/services/tailscale-saas.nix` module in the full gnomeregan Colmena configuration. Do not configure an auth key, subnet routes, an exit node, or service-specific Tailscale ACLs.

Tailscale will be enabled after deployment but remain unauthenticated until the administrator logs in interactively. On gnomeregan, run `sudo tailscale up`, open the emitted URL, and sign in to the existing tailnet. Tailscale persists the resulting node state.

## Verification
Evaluate or build the gnomeregan Colmena configuration and confirm the Tailscale SaaS module is included in the full host configuration. After deployment and interactive enrollment, confirm `tailscale status` lists gnomeregan as connected.
