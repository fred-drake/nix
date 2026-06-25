# Pi coding agent (https://pi.dev) — a minimal terminal coding harness.
#
# Built from the tagged earendil-works/pi monorepo source (apps/pi-coding-agent.nix)
# rather than the nixpkgs package, so we track upstream releases the day they land.
# Bump with `just update-pi` (regenerates apps/fetcher/pi-coding-agent.nix).
#
# Packages/extensions are managed declaratively here instead of via `pi install`.
# settings.json is a read-only Nix symlink — runtime writes (e.g. /settings,
# /model) are intentionally not supported; change settings here and run
# `just switch`. lastChangelogVersion is pinned to pi-coding-agent.version so
# pi never tries to rewrite it. Auth (`/login`) lives in ~/.pi/agent/auth.json
# which is intentionally left mutable.
{
  pkgs,
  lib,
  config,
  ...
}: let
  pi-coding-agent = pkgs.callPackage ../../../apps/pi-coding-agent.nix {
    pi-pin = import ../../../apps/fetcher/pi-coding-agent.nix;
  };

  # Pi packages registered via local-path `packages` entries. Each must be a
  # built package directory in the store (apps/pi-*.nix).
  piPackages = [
    (pkgs.callPackage ../../../apps/pi-dynamic-workflows.nix {
      pin = import ../../../apps/fetcher/pi-dynamic-workflows.nix;
    })
    (pkgs.callPackage ../../../apps/pi-web-access.nix {
      pin = import ../../../apps/fetcher/pi-web-access.nix;
    })
    (pkgs.callPackage ../../../apps/pi-mcp-adapter.nix {
      pin = import ../../../apps/fetcher/pi-mcp-adapter.nix;
    })
  ];

  # Directory of prompt templates pi should discover. We reuse the Claude Code
  # slash-command files (symlinked to ~/.claude/commands by the claude-code
  # feature); pi loads *.md from any directory listed in the `prompts` array,
  # exposing each as a /name command. Discovery is non-recursive.
  promptsDir = "${config.home.homeDirectory}/.claude/commands";

  # Claude Code "dynamic workflow" scripts (apps/claude-code/workflows/*.js) are
  # already written against the pi-dynamic-workflows runtime API
  # (`export const meta`, `agent()`, `phase()`). pi does not scan ~/.claude;
  # it loads saved workflows as <name>.json files (shape {name, description,
  # script, ...}) from ~/.pi/workflows/saved. The activation below transcodes
  # each .js into that JSON so the same definition powers `/name` in both
  # Claude Code and pi.
  workflowsSrc = ../../../apps/claude-code/workflows;
  savedWorkflowsDir = "${config.home.homeDirectory}/.pi/workflows/saved";

  # Local pi extensions (apps/pi-extensions/*.ts). Copied to the Nix store
  # as a read-only directory and registered via the `extensions` settings key
  # so pi auto-discovers them without needing a ~/.pi/agent/extensions symlink.
  piExtensionsDir = ../../../apps/pi-extensions;

  jq = lib.getExe pkgs.jq;

  # Fully declarative settings.json — symlinked read-only from the Nix store.
  # lastChangelogVersion is pinned to the current pi version so pi never
  # attempts to write an updated value to the read-only file.
  settingsJson = pkgs.writeText "pi-agent-settings.json" (builtins.toJSON {
    lastChangelogVersion = pi-coding-agent.version;
    theme = "dark";
    defaultProvider = "anthropic";
    defaultModel = "claude-sonnet-4-6";
    defaultThinkingLevel = "high";
    packages = map toString piPackages;
    prompts = [promptsDir];
    extensions = ["${piExtensionsDir}"];
  });
in {
  home = {
    packages = [pi-coding-agent];

    file.".pi/agent/settings.json".source = settingsJson;

    # Transcode each Claude dynamic-workflow .js into a pi saved-workflow .json
    # at the user level so /commit-and-push (etc.) is available in every project.
    # Idempotent: rewrites the names we own each generation; pi may still
    # add/remove its own saved workflows alongside these.
    activation.piSavedWorkflows = lib.hm.dag.entryAfter ["writeBoundary"] ''
      saved="${savedWorkflowsDir}"
      $DRY_RUN_CMD mkdir -p "$saved"
      for src in ${workflowsSrc}/*.js; do
        [ -e "$src" ] || continue
        name="$(${pkgs.coreutils}/bin/basename "$src" .js)"
        desc="$(${pkgs.gnugrep}/bin/grep -m1 'description:' "$src" \
          | ${pkgs.gnused}/bin/sed -E "s/.*description: *'([^']*)'.*/\1/")"
        [ -n "$desc" ] || desc="$name"
        out="$saved/$name.json"
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        if ${jq} -n \
            --arg name "$name" \
            --arg description "$desc" \
            --rawfile script "$src" \
            '{name: $name, description: $description, script: $script, location: "user"}' \
            > "$tmp"; then
          $DRY_RUN_CMD mv "$tmp" "$out"
        else
          echo "pi: failed to generate saved workflow for $name" >&2
          $DRY_RUN_CMD rm -f "$tmp"
        fi
      done
    '';
  };
}
