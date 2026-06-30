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
    (pkgs.callPackage ../../../apps/pi-interactive-subagents.nix {
      pin = import ../../../apps/fetcher/pi-interactive-subagents.nix;
    })
    (pkgs.callPackage ../../../apps/pi-lsp.nix {
      pin = import ../../../apps/fetcher/pi-lsp.nix;
    })
    (pkgs.callPackage ../../../apps/pi-hypa.nix {
      pin = import ../../../apps/fetcher/pi-hypa.nix;
    })
    (pkgs.callPackage ../../../apps/pi-context-mode.nix {
      pin = import ../../../apps/fetcher/pi-context-mode.nix;
    })
    (pkgs.callPackage ../../../apps/pi-ask-user-question.nix {
      pin = import ../../../apps/fetcher/pi-ask-user-question.nix;
    })
    (pkgs.callPackage ../../../apps/pi-rpiv-todo.nix {
      pin = import ../../../apps/fetcher/pi-rpiv-todo.nix;
    })
    (pkgs.callPackage ../../../apps/pi-simplify.nix {
      pin = import ../../../apps/fetcher/pi-simplify.nix;
    })
    (pkgs.callPackage ../../../apps/pi-goal-x.nix {
      pin = import ../../../apps/fetcher/pi-goal-x.nix;
    })
  ];

  # Directory of prompt templates pi should discover. We reuse the Claude Code
  # slash-command files (symlinked to ~/.claude/commands by the claude-code
  # feature); pi loads *.md from any directory listed in the `prompts` array,
  # exposing each as a /name command. Discovery is non-recursive.
  promptsDir = "${config.home.homeDirectory}/.claude/commands";

  # Shared "dynamic workflow" scripts (apps/agent-common/workflows/*.js) are
  # already written against the pi-dynamic-workflows runtime API
  # (`export const meta`, `agent()`, `phase()`). pi does not scan ~/.claude;
  # it loads saved workflows as <name>.json files (shape {name, description,
  # script, ...}) from ~/.pi/workflows/saved. The activation below transcodes
  # each .js into that JSON so the same definition powers `/name` in both
  # Claude Code and pi.
  workflowsSrc = ../../../apps/agent-common/workflows;
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
    skills = ["${config.home.homeDirectory}/plugins/cmux/skills" "${config.home.homeDirectory}/plugins/superpowers/skills" "${config.home.homeDirectory}/plugins/andrej-karpathy-skills/skills"];
  });
in {
  home = {
    sessionVariables = {
      # Switch pi-hypa from additive mode (adds hypa_* tools alongside the
      # built-ins) to replace mode (hypa_* tools replace bash/read/grep/find/ls
      # so verbose output never reaches the context window).
      HYPA_PI_MODE = "replace";
    };

    packages = [
      pi-coding-agent
      (pkgs.callPackage ../../../apps/hypa.nix {
        pin = import ../../../apps/fetcher/hypa.nix;
      })
    ];

    file = {
      ".pi/agent/settings.json".source = settingsJson;

      # LSP server configuration for pi-lsp. Global config is trusted automatically.
      # Project-local .pi/lsp.json entries can override or disable these per-project.
      ".pi/agent/lsp.json".text = builtins.toJSON {
        version = 1;
        servers = [
          {
            id = "gopls";
            enabled = true;
            include = ["**/*.go"];
            rootMarkers = ["go.mod" ".git"];
            bin = "gopls";
            args = [];
            cwd = "{root}";
            languageIdByExtension = {".go" = "go";};
            startupTimeoutMs = 45000;
            diagnosticsWaitMs = 1500;
            initializationOptions = {};
            settings = {};
          }
          {
            id = "rust-analyzer";
            enabled = true;
            include = ["**/*.rs"];
            rootMarkers = ["Cargo.toml" ".git"];
            bin = "rust-analyzer";
            args = [];
            cwd = "{root}";
            languageIdByExtension = {".rs" = "rust";};
            startupTimeoutMs = 45000;
            diagnosticsWaitMs = 2000;
            initializationOptions = {};
            settings = {};
          }
          {
            id = "sourcekit-lsp";
            enabled = true;
            include = ["**/*.swift"];
            rootMarkers = ["Package.swift" ".git"];
            # Use the macOS shim — delegates to the active Xcode toolchain
            # (Swift 6.3+). Do NOT use a bare name; the nixpkgs 5.10.1 binary
            # would shadow it via PATH and break Swift 6 diagnostics.
            bin = "/usr/bin/sourcekit-lsp";
            args = [];
            cwd = "{root}";
            languageIdByExtension = {".swift" = "swift";};
            startupTimeoutMs = 60000;
            diagnosticsWaitMs = 2000;
            initializationOptions = {};
            settings = {};
          }
        ];
      };

      # cmux session-hook extension: bridges Pi lifecycle events (session_start,
      # before_agent_start, agent_end) into cmux's restorable session store so
      # cmux can show running/idle state, send notifications, and resume Pi
      # sessions after an app relaunch.
      #
      # The extension lives in apps/pi-extensions/cmux-session.ts which is
      # already discovered via the `extensions` key in settings.json above.
      # We ALSO create a symlink at the canonical cmux location
      # (~/.pi/agent/extensions/cmux-session.ts) pointing to the *same*
      # Nix-store path.  Pi's discoverAndLoadExtensions() deduplicates by
      # resolved path (Set<string>), so the extension is loaded exactly once
      # even though two discovery paths both point to it.  The symlink also
      # prevents `cmux hooks pi install` from silently replacing our managed
      # version with a stale copy (it would overwrite the symlink with a
      # different path, causing a duplicate; running `just switch` restores it).
      #
      # Darwin-only because cmux is a macOS app. The extension itself is safe
      # elsewhere (it short-circuits when CMUX_SURFACE_ID is unset).
      ".pi/agent/extensions/cmux-session.ts" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = "${piExtensionsDir}/cmux-session.ts";
      };
    };

    # On macOS, GUI apps (cmux → pi) inherit the launchd per-user environment,
    # not the shell profile. Push HYPA_PI_MODE into launchd so pi-hypa's
    # replace mode is active regardless of how pi is launched.
    activation.hypaLaunchdEnv =
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD /bin/launchctl setenv HYPA_PI_MODE replace
      '');

    # Transcode each shared dynamic-workflow .js into a pi saved-workflow .json
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
