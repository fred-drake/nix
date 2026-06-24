# Pi coding agent (https://pi.dev) — a minimal terminal coding harness.
#
# Built from the tagged earendil-works/pi monorepo source (apps/pi-coding-agent.nix)
# rather than the nixpkgs package, so we track upstream releases the day they land.
# Bump with `just update-pi` (regenerates apps/fetcher/pi-coding-agent.nix).
#
# Packages/extensions are managed declaratively here instead of via `pi install`:
# each pi package is built into the nix store (apps/pi-*.nix) and registered by
# pointing a local-path entry in pi's `packages` array at the store path. We merge
# that entry into ~/.pi/agent/settings.json with an activation script rather than
# managing the whole file, because pi writes to settings.json at runtime
# (lastChangelogVersion, interactive /settings, /model) — a read-only nix symlink
# would break those writes.
#
# Runtime state (auth via `/login`, settings) otherwise lives under ~/.pi/agent/
# and is intentionally left mutable.
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
  # built package directory in the store (apps/pi-*.nix). The activation script
  # below reconciles ~/.pi/agent/settings.json to exactly this set of nix-managed
  # entries (dropping any stale store paths from previous generations) while
  # preserving every other key and any non-nix package the user added.
  piPackages = [
    (pkgs.callPackage ../../../apps/pi-dynamic-workflows.nix {
      pin = import ../../../apps/fetcher/pi-dynamic-workflows.nix;
    })
  ];

  settingsFile = "${config.home.homeDirectory}/.pi/agent/settings.json";
  jq = lib.getExe pkgs.jq;

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
  # Marker identifying entries we own: every nix-managed pi package lives under
  # the store and was built by an apps/pi-*.nix derivation.
  managedPaths = lib.concatStringsSep "\n" (map toString piPackages);
in {
  home = {
    packages = [pi-coding-agent];

    # Merge our nix-built pi packages into the (mutable) settings.json packages
    # array. Idempotent: strips any previously-managed store paths, then appends
    # the current generation's set. Leaves the file untouched if it is not valid
    # JSON (jq fails, the `&&` short-circuits, the original is preserved).
    # Transcode each Claude dynamic-workflow .js into a pi saved-workflow .json at
    # the user level so /commit-and-push (etc.) is available in every project.
    # Idempotent: rewrites only the names we own each generation; pi may still
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

    activation.piManagedPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      settings="${settingsFile}"
      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -f "$settings" ] || echo '{}' > "$settings"

      managed="${managedPaths}"
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if ${jq} \
          --arg managed "$managed" \
          --arg prompts "${promptsDir}" '
            ($managed | split("\n") | map(select(length > 0))) as $paths
            | .packages = (
                ((.packages // [])
                  | map(select(
                      (type != "string") or (test("^/nix/store/") | not)
                    )))
                + $paths
              )
            | .prompts = (
                ((.prompts // [])
                  | map(select(. != $prompts)))
                + [$prompts]
              )
          ' "$settings" > "$tmp"; then
        $DRY_RUN_CMD mv "$tmp" "$settings"
      else
        echo "pi: leaving $settings unchanged (not valid JSON?)" >&2
        $DRY_RUN_CMD rm -f "$tmp"
      fi
    '';
  };
}
