# Actual MCP — Design

## Goal

Provide the `actual-mcp` MCP server as a declaratively configured, reproducibly built local command for Claude Code and other clients that load `~/mcp/actual.json`.

## Configuration

- Package the pinned `s-stefanov/actual-mcp` GitHub source with Nix, following the existing local MCP packaging convention.
- Add a SOPS secret declaration named `actual-password`, sourced from `config.secrets.workstation.mcp.actual` at key `password`.
- Render `~/mcp/actual.json` with mode `0400`. It invokes the packaged `actual-mcp` binary, passes `--enable-write`, and sets:
  - `ACTUAL_SERVER_URL=https://actual.internal.freddrake.com`
  - `ACTUAL_PASSWORD` from the SOPS placeholder.
- Set `ACTUAL_BUDGET_SYNC_ID=0da0a210-9782-4137-ad4a-4b6ec2edb08b` because automatic selection chose a stale local budget. Omit the optional budget-encryption password because it is not needed for this deployment.

## Safety and operations

Write tools are intentionally enabled at the user's request. The MCP configuration remains mode `0400`, and the password is supplied only at SOPS activation time rather than stored in the Nix store.

## Verification

Evaluate the Home Manager configuration, confirm the package builds, and inspect the generated JSON to verify the server URL, write flag, and SOPS placeholder wiring without revealing secret material.
