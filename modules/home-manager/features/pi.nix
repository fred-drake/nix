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
    (pkgs.callPackage ../../../apps/pi-web-access.nix {
      pin = import ../../../apps/fetcher/pi-web-access.nix;
    })
    (pkgs.callPackage ../../../apps/pi-mcp-adapter.nix {
      pin = import ../../../apps/fetcher/pi-mcp-adapter.nix;
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
    (pkgs.callPackage ../../../apps/pi-hooks.nix {
      pin = import ../../../apps/fetcher/pi-hooks.nix;
    })
  ];

  # Directory of prompt templates pi should discover. We reuse the Claude Code
  # slash-command files (symlinked to ~/.claude/commands by the claude-code
  # feature); pi loads *.md from any directory listed in the `prompts` array,
  # exposing each as a /name command. Discovery is non-recursive.
  promptsDir = "${config.home.homeDirectory}/.claude/commands";

  # Local pi extensions (apps/pi-extensions/*.ts). Copied to the Nix store
  # as a read-only directory and registered via the `extensions` settings key
  # so pi auto-discovers them without needing a ~/.pi/agent/extensions symlink.
  piExtensionsDir = ../../../apps/pi-extensions;

  # Custom providers, authored as native Nix attrsets. The full models.json
  # (including the opencode/Xai provider with its apiKey from the llm-xai
  # sops secret) is rendered at activation by sops-nix via
  # sops.templates.pi-models below — the apiKey placeholder survives
  # builtins.toJSON and is substituted at activation, never baked into the
  # world-readable Nix store.
  openRouterRouting = {
    sort = "price";
    quantizations = ["bf16" "fp16" "fp8"];
  };
  mkOpenRouterModel = id: name: {
    inherit id name;
    overrides = {inherit openRouterRouting;};
  };
  staticProviders = {
    openrouter = {
      baseUrl = "https://openrouter.ai/api/v1";
      models = [
        (mkOpenRouterModel "deepseek/deepseek-v4-pro" "DeepSeek (cheap, high precision)")
        (mkOpenRouterModel "minimax/MiniMax-M3" "MiniMax M3 (cheap, high precision)")
        (mkOpenRouterModel "openrouter/z-ai/glm-5.2" "GLM-5.2 (cheap, high precision)")
      ];
    };
    # Local Ollama server (brew install ollama; ollama serve). Ollama exposes
    # an OpenAI-compatible API at /v1, so pi uses openai-completions. The
    # model below is a Qwen 3.x reasoning model that emits <think>…</think>
    # blocks — thinkingFormat: "qwen" maps pi's /thinking levels onto the
    # enable_thinking toggle Ollama understands. No apiKey: Ollama accepts
    # any non-empty string. Switch with: /model ollama/qwen3.6:35b
    ollama = {
      baseUrl = "http://localhost:11434/v1";
      apiKey = "not-needed";
      api = "openai-completions";
      models = [
        {
          id = "qwen3.6:35b";
          name = "Qwen 3.6 35B (local)";
          reasoning = true;
          input = ["text"];
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          contextWindow = 262144;
          maxTokens = 16384;
          compat = {
            supportsDeveloperRole = false;
            maxTokensField = "max_tokens";
            thinkingFormat = "qwen";
          };
        }
        {
          id = "qwen3.6:27b";
          name = "Qwen 3.6 27B";
          reasoning = true;
          input = ["text"];
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          contextWindow = 262144;
          maxTokens = 16384;
          compat = {
            supportsDeveloperRole = false;
            maxTokensField = "max_tokens";
            thinkingFormat = "qwen";
          };
        }
        {
          id = "qwen3.6-27b-temp06";
          name = "Qwen 3.6 27B temp 0.6 (local)";
          reasoning = true;
          input = ["text"];
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          contextWindow = 262144;
          maxTokens = 16384;
          compat = {
            supportsDeveloperRole = false;
            maxTokensField = "max_tokens";
            thinkingFormat = "qwen";
          };
        }
      ];
    };
  };
  # Xai provider (grok-4.5). The apiKey is a sops-nix placeholder —
  # builtins.toJSON encodes it as a quoted JSON string and sops-nix substitutes
  # the real value at activation.
  xaiProvider = {
    apiKey = config.sops.placeholder.llm-xai;
    models = [
      {
        id = "grok-4.5";
        name = "Grok 4.5";
        reasoning = true;
        input = ["text" "image"];
        contextWindow = 500000;
        maxTokens = 500000;
        cost = {
          input = 2;
          output = 6;
          cacheRead = 0.5;
          cacheWrite = 0;
        };
        compat = {
          supportsStore = false;
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
      }
    ];
    api = "openai-completions";
    baseUrl = "https://api.x.ai/v1";
  };

  # Full models.json content, serialized with builtins.toJSON. The apiKey
  # placeholder inside xaiProvider survives JSON encoding as a quoted string
  # and is substituted at activation by sops-nix.
  modelsJson = builtins.toJSON {
    providers = staticProviders // {xai = xaiProvider;};
  };

  # Fully declarative settings.json — symlinked read-only from the Nix store.
  # lastChangelogVersion is pinned to the current pi version so pi never
  # attempts to write an updated value to the read-only file.
  settingsJson = pkgs.writeText "pi-agent-settings.json" (builtins.toJSON {
    lastChangelogVersion = pi-coding-agent.version;
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.5";
    defaultThinkingLevel = "low";
    packages = map toString piPackages;
    prompts = [promptsDir];
    extensions = ["${piExtensionsDir}"];
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "CMD=$(python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('command',''))\" 2>/dev/null || true); case \"$CMD\" in *grep*|*rg\\ *|*ripgrep*|*find\\ *|*fd\\ *|*ack\\ *|*ag\\ *)   [ -f graphify-out/graph.json ] &&   echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"MANDATORY: graphify-out/graph.json exists. You MUST run `graphify query \\\"<question>\\\"` before grepping raw files. Only grep after graphify has oriented you, or to modify/debug specific lines.\"}}'   || true ;; esac";
            }
          ];
        }
        {
          matcher = "Read|Glob";
          hooks = [
            {
              type = "command";
              command = "HIT=$(python3 -c \"import json,sys;d=json.load(sys.stdin);t=d.get('tool_input',d);s=(str(t.get('file_path') or '')+' '+str(t.get('pattern') or '')+' '+str(t.get('path') or '')).lower().replace(chr(92),'/');exts=('.py','.js','.ts','.tsx','.jsx','.go','.rs','.java','.rb','.c','.h','.cpp','.hpp','.cc','.cs','.kt','.swift','.php','.scala','.lua','.sh','.md','.rst','.txt','.mdx');sys.stdout.write('1' if 'graphify-out/' not in s and any(e in s for e in exts) else '')\" 2>/dev/null || true); if [ \"$HIT\" = 1 ] && [ -f graphify-out/graph.json ]; then echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"MANDATORY: graphify-out/graph.json exists. You MUST run graphify before reading source files. Use: `graphify query \\\"<question>\\\"` (scoped subgraph), `graphify explain \\\"<concept>\\\"`, or `graphify path \\\"<A>\\\" \\\"<B>\\\"`. Only read raw files after graphify has oriented you, or to modify/debug specific lines. This rule applies to subagents too — include it in every subagent prompt involving code exploration.\"}}'; fi || true";
            }
          ];
        }
      ];
    };
    skills = [
      "${config.home.homeDirectory}/plugins/cmux/skills"
      "${config.home.homeDirectory}/plugins/superpowers/skills"
      "${config.home.homeDirectory}/plugins/andrej-karpathy-skills/skills"
      "${config.home.homeDirectory}/plugins/agent-rules-skill/skills"
      "${config.home.homeDirectory}/plugins/herdr/skills"
    ];
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
      # Generic user-level agent instructions shared with Claude Code.
      ".pi/agent/AGENTS.md".text = builtins.readFile ../../../apps/agent-common/AGENTS.md;

      ".pi/agent/settings.json".source = settingsJson;

      # Custom models.json is rendered by sops-nix at activation via
      # sops.templates.pi-models (below) — it includes the xai provider
      # with the Xai apiKey from the llm-xai secret.

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
      # cmux-pi-subagent skill: spawns a visible cmux pane, drives a pi RPC
      # subagent inside it, collects the answer, and closes the pane. Placed
      # in ~/.pi/agent/skills/ which pi auto-discovers at startup (no
      # settings.json change needed). Darwin-only because it requires cmux.
      ".pi/agent/skills/cmux-pi-subagent" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = ../../../apps/pi-skills/cmux-pi-subagent;
        recursive = true;
      };

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
  };

  # Render ~/.pi/agent/models.json at activation with the Xai apiKey
  # substituted from the llm-xai sops secret. The static providers
  # (openrouter + ollama) and the xai provider are built as a Nix attrset,
  # serialized with builtins.toJSON, and the apiKey placeholder is substituted
  # at activation by sops-nix — never baked into the store.
  sops.templates.pi-models = {
    path = "${config.home.homeDirectory}/.pi/agent/models.json";
    mode = "0400";
    content = modelsJson;
  };
}
