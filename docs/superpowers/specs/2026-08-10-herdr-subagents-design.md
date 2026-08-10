# Herdr Subagents Design

## Goal

Configure Pi declaratively so interactive subagents run in a new Herdr tab, rather than splitting the parent pane. The `pi-subagents` extension provides the delegation tools directly; no custom skill is added.

## Decision

Use [`edxeth/pi-subagents`](https://github.com/edxeth/pi-subagents), not `pi-herdr`.

`pi-subagents` is Pi's named-subagent framework: it provides the `subagent` lifecycle, asynchronous result routing, resume and interruption tools, and a selectable terminal multiplexer backend. With the parent Pi process running inside Herdr, it creates visible child sessions. The parent environment variable `PI_SUBAGENT_HERDR_PLACEMENT=tab` selects a dedicated Herdr tab with one child pane for every interactive child.

`pi-herdr` is useful operational inspiration—create, name, inspect, wait for, and close visible agents—but its generic `herdr_*` tools create a split pane on current Herdr versions. It is not the selected execution layer.

## Configuration

1. Pin `edxeth/pi-subagents` in `apps/fetcher/repos.toml` and package that Git source as a local Pi package, following the repository's existing `apps/pi-*.nix` pattern.
2. Add that package to `piPackages` in `modules/home-manager/features/pi.nix` so it is declaratively registered in Pi's read-only settings.
3. Set the parent-level environment in the Pi Home Manager module:
   - `PI_SUBAGENT_MUX=herdr`
   - `PI_SUBAGENT_HERDR_PLACEMENT=tab`

Herdr's existing integration and the extension's own tools are sufficient for this scope. No custom skill, managed Herdr lifecycle extension, or globally installed agent definition is added.

## Operating Model

`pi-subagents` discovers named agent definitions under `~/.pi/agent/agents/` or `.pi/agents/`. Users can create those definitions when they need specialized roles. An interactive named agent opens in a dedicated tab because of the global placement setting; background agents remain headless.

The initial configuration does not force orchestrator-only mode, install opinionated global agent roles, enable nested delegation, or add a separate prompt skill. Those policies can be added later if actual use shows a need.

## Verification

- Nix evaluation confirms the Pi settings reference the new package and exports both placement variables.
- Pi loads the package and exposes subagent tools.
- In a live Herdr session, launch an interactive test agent and confirm it appears as the sole pane in a newly created tab, not beside the parent.
- Confirm the child result returns to the parent.

## Sources

- `edxeth/pi-subagents` README and source: Herdr backend selection and `PI_SUBAGENT_HERDR_PLACEMENT=tab`.
- Herdr CLI reference: a tab is a dedicated terminal layout with a root pane; `agent start` attaches an agent to an existing pane.
- `AndrewJacop/pi-herdr` documentation: operational model and lifecycle/reporting inspiration; its current agent-start path creates a split pane.
