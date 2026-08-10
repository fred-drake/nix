# Remove cmux agent integrations

## Scope

Remove cmux-specific integrations from Pi and Claude Code, without changing the standalone cmux workstation configuration.

## Changes

- Remove Pi's cmux session extension, cmux subagent skill, and cmux skill directory.
- Remove Claude Code's cmux wrapper/filter and opt-in cmux plugin.
- Remove the cmux plugin-source fetcher entry.
- Delete local Pi-only cmux extension and subagent source files once unreferenced.

## Verification

Evaluate the affected Home Manager configuration and confirm no remaining references to the removed agent integration paths.
