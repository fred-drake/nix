{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  # cmux ships a `claude` wrapper that injects --session-id + --settings (a hook
  # bundle) so Claude Code drives cmux's Feed approvals, "Needs input" status
  # ring, notifications, and session restore. cmux normally puts this wrapper on
  # PATH via its zsh/bash shell integration, which our Nix-managed fish/zsh setup
  # never sources — so on Darwin we route ~/.local/bin/claude (first on PATH)
  # through it instead. See the ~/.local/bin/claude home.file entry below.
  cmuxClaudeWrapper = pkgs.stdenv.hostPlatform.isDarwin;
  claude-plugins-src = import ../../../apps/fetcher/claude-plugins-src.nix {inherit pkgs;};
  lsp-plugin = import ../../../apps/claude-code/lsp-plugin.nix {
    inherit pkgs;
    inherit (claude-plugins-src) claude-plugins-official-src;
  };
  claude-code = pkgs.callPackage ../../../apps/claude-code {
    pluginDirs = [
      "$HOME/.claude/lsp-plugin"
    ];
  };
  gitea-mcp = pkgs.callPackage ../../../apps/gitea-mcp.nix {};
  ccstatusline = pkgs.callPackage ../../../apps/ccstatusline.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
  };
  claude-usage = pkgs.callPackage ../../../apps/claude-usage.nix {};
  ccusage-bar = import ../../../apps/ccusage-bar.nix {inherit pkgs;};
in {
  # Add Claude Code and Gitea MCP packages
  home.packages = [
    claude-code # Claude Code CLI tool
    gitea-mcp # Gitea MCP server
    claude-usage # Claude Code usage JSON fetcher
    pkgs.uv # uvx, used to run workspace-mcp and other Python MCP servers

    # LSP servers (used by the nix-managed-lsp plugin)
    pkgs.nil # Nix
    pkgs.pyright # Python
    pkgs.typescript-language-server # TypeScript/JavaScript
    pkgs.gopls # Go
    pkgs.rust-analyzer # Rust
    pkgs.jdt-language-server # Java
  ];

  # SOPS templates for MCP configuration
  sops.templates = {
    mcp-browser = {
      mode = "0400";
      path = "${home}/mcp/browser.json";
      content = builtins.toJSON {
        mcpServers = {
          browser = {
            command = "npx";
            args = ["@browsermcp/mcp@latest"];
          };
        };
      };
    };
    mcp-chrome = {
      mode = "0400";
      path = "${home}/mcp/chrome.json";
      content = builtins.toJSON {
        mcpServers = {
          chrome = {
            command = "npx";
            args = ["-y" "chrome-devtools-mcp@latest" "--browserUrl=http://127.0.0.1:9222"];
          };
        };
      };
    };
    mcp-brave = {
      mode = "0400";
      path = "${home}/mcp/brave.json";
      content = builtins.toJSON {
        mcpServers = {
          brave-search = {
            command = "npx";
            args = ["-y" "@modelcontextprotocol/server-brave-search"];
            env = {"BRAVE_API_KEY" = config.sops.placeholder.llm-brave;};
          };
        };
      };
    };
    mcp-playwright = {
      mode = "0400";
      path = "${home}/mcp/playwright.json";
      content = builtins.toJSON {
        mcpServers = {
          playwright = {
            command = "podman";
            args = ["run" "-i" "--rm" "--init" "--pull=always" "--add-host=local.brainrush.ai:host-gateway" "mcr.microsoft.com/playwright/mcp"];
          };
        };
      };
    };
    mcp-context7 = {
      mode = "0400";
      path = "${home}/mcp/context7.json";
      content = builtins.toJSON {
        mcpServers = {
          context7 = {
            command = "npx";
            args = ["-y" "@upstash/context7-mcp"];
          };
        };
      };
    };
    mcp-gitea-personal = {
      mode = "0400";
      path = "${home}/mcp/gitea-personal.json";
      content = builtins.toJSON {
        mcpServers = {
          gitea-personal = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.personal-gitea-token;};
          };
        };
      };
    };
    mcp-gitea-engineer = {
      mode = "0400";
      path = "${home}/mcp/gitea-engineer.json";
      content = builtins.toJSON {
        mcpServers = {
          gitea-engineer = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.engineer-gitea-token;};
          };
        };
      };
    };
    mcp-gitea-product-owner = {
      mode = "0400";
      path = "${home}/mcp/gitea-product-owner.json";
      content = builtins.toJSON {
        mcpServers = {
          gitea-product-owner = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.product-owner-gitea-token;};
          };
        };
      };
    };
    mcp-gitea-code-architect = {
      mode = "0400";
      path = "${home}/mcp/gitea-code-architect.json";
      content = builtins.toJSON {
        mcpServers = {
          gitea-code-architect = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.code-architect-gitea-token;};
          };
        };
      };
    };
    mcp-gitea-reviewer = {
      mode = "0400";
      path = "${home}/mcp/gitea-reviewer.json";
      content = builtins.toJSON {
        mcpServers = {
          gitea-reviewer = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.reviewer-gitea-token;};
          };
        };
      };
    };
    mcp-github = {
      mode = "0400";
      path = "${home}/mcp/github.json";
      content = builtins.toJSON {
        mcpServers = {
          github = {
            command = "podman";
            args = ["run" "-i" "--rm" "-e" "GITHUB_PERSONAL_ACCESS_TOKEN" "ghcr.io/github/github-mcp-server"];
            env = {GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.placeholder.github-token;};
          };
        };
      };
    };
    mcp-ref = {
      mode = "0400";
      path = "${home}/mcp/ref.json";
      content = builtins.toJSON {
        mcpServers = {
          ref = {
            command = "npx";
            args = ["ref-tools-mcp@latest"];
            env = {"REF_API_KEY" = config.sops.placeholder.ref-mcp-api-key;};
          };
        };
      };
    };

    mcp-shadcn = {
      mode = "0400";
      path = "${home}/mcp/shadcn.json";
      content = builtins.toJSON {
        mcpServers = {
          shadcn = {
            command = "npx";
            args = ["-y" "shadcn@latest" "mcp"];
          };
        };
      };
    };

    mcp-firecrawl = {
      mode = "0400";
      path = "${home}/mcp/firecrawl.json";
      content = builtins.toJSON {
        mcpServers = {
          firecrawl = {
            command = "npx";
            args = ["-y" "firecrawl-mcp"];
            env = {"FIRECRAWL_API_KEY" = config.sops.placeholder.firecrawl-api-key;};
          };
        };
      };
    };

    mcp-stripe-sandbox = {
      mode = "0400";
      path = "${home}/mcp/stripe-sandbox.json";
      content = builtins.toJSON {
        mcpServers = {
          stripe = {
            command = "npx";
            args = ["-y" "@stripe/mcp" "--tools=all"];
            env = {"STRIPE_SECRET_KEY" = config.sops.placeholder.stripe-sandbox-api-key;};
          };
        };
      };
    };

    mcp-google-sheets = {
      mode = "0400";
      path = "${home}/mcp/google-sheets.json";
      content = builtins.toJSON {
        mcpServers = {
          google-sheets = {
            command = "uvx";
            args = ["mcp-google-sheets@latest"];
            env = {
              SERVICE_ACCOUNT_PATH = config.sops.secrets.google-service-account.path;
              DRIVE_FOLDER_ID = config.soft-secrets.workstation.google-service-drive-id;
            };
          };
        };
      };
    };

    mcp-gmail = {
      mode = "0400";
      path = "${home}/mcp/gmail.json";
      content = builtins.toJSON {
        mcpServers = {
          gmail = {
            command = "uvx";
            # args = ["run" "--directory" "${home}/Source/github.com/fred-drake/gmail-mcp" "gmail-mcp"];
            args = ["--from" "git+https://github.com/fred-drake/gmail-mcp" "gmail-mcp"];
            env = {
              GMAIL_MCP_CREDENTIALS_PATH = config.sops.secrets.google-oauth.path;
            };
          };
        };
      };
    };

    mcp-google-workspace = {
      mode = "0400";
      path = "${home}/mcp/google-workspace.json";
      content = builtins.toJSON {
        mcpServers = {
          google-workspace = {
            command = "uvx";
            args = ["--with" "aiofile<3.10" "workspace-mcp" "--tools" "gmail"];
            env = {
              GOOGLE_OAUTH_CLIENT_ID = config.sops.placeholder.google-workspace-client-id;
              GOOGLE_OAUTH_CLIENT_SECRET = config.sops.placeholder.google-workspace-client-secret;
              USER_GOOGLE_EMAIL = "fred.drake@gmail.com";
            };
          };
        };
      };
    };

    mcp-zohomail = {
      mode = "0400";
      path = "${home}/mcp/zohomail.json";
      content = builtins.toJSON {
        mcpServers = {
          zohomail = {
            command = "npx";
            args = ["mcp-remote" config.sops.secrets.zohomail-mcp-url "--transport" "http-only"];
          };
        };
      };
    };

    mcp-trello = {
      mode = "0400";
      path = "${home}/mcp/trello.json";
      content = builtins.toJSON {
        mcpServers = {
          trello = {
            command = "npx";
            args = ["-y" "@delorenj/mcp-server-trello"];
            env = {
              TRELLO_API_KEY = config.sops.placeholder.trello-legacy-api-key;
              TRELLO_TOKEN = config.sops.placeholder.trello-legacy-api-token;
            };
          };
        };
      };
    };

    mcp-ios-simulator = {
      mode = "0400";
      path = "${home}/mcp/ios-simulator.json";
      content = builtins.toJSON {
        mcpServers = {
          ios-simulator = {
            command = "npx";
            args = ["-y" "ios-simulator-mcp"];
          };
        };
      };
    };

    mcp-figma = {
      mode = "0400";
      path = "${home}/mcp/figma.json";
      content = builtins.toJSON {
        mcpServers = {
          figma = {
            type = "http";
            url = "https://mcp.figma.com/mcp";
          };
        };
      };
    };
    mcp-resume = {
      mode = "0400";
      path = "${home}/mcp/resume.json";
      content = builtins.toJSON {
        mcpServers = {
          resume = {
            type = "http";
            url = "https://resume.${config.soft-secrets.networking.domain}/mcp";
            headers = {
              x-api-key = config.sops.placeholder.resume-api-key;
            };
          };
        };
      };
    };
  };

  # Claude Code configuration files
  home.file = {
    # ~/.local/bin is first on PATH, so this slot decides which `claude` runs.
    # On Darwin, point it at cmux's claude wrapper: it injects --session-id +
    # the hook bundle (Feed approvals, status ring, notifications, session
    # restore) and then execs the real nix claude, which it finds as the next
    # `claude` on PATH (/etc/profiles/per-user/<user>/bin/claude). The wrapper
    # passes through transparently outside a live cmux session, and if cmux is
    # absent this symlink dangles and shells skip it, falling back to the same
    # real claude — so it is safe on any Darwin host. Elsewhere, point straight
    # at the real claude (also satisfies Claude's native installer check).
    ".local/bin/claude".source = config.lib.file.mkOutOfStoreSymlink (
      if cmuxClaudeWrapper
      then "/Applications/cmux.app/Contents/Resources/bin/claude"
      else "/etc/profiles/per-user/${config.home.username}/bin/claude"
    );

    # Claude command files
    ".claude/commands" = {
      source = ../../../apps/claude-code/commands;
      recursive = true;
    };

    ".claude/agents" = {
      source = ../../../apps/claude-code/agents;
      recursive = true;
    };

    ".claude/skills" = {
      source = ../../../apps/claude-code/skills;
      recursive = true;
    };

    # Ralph Wiggum assets (scripts and hooks for the ralph-loop command)
    ".claude/assets/ralph-wiggum" = {
      source = ../../../apps/claude-code/assets/ralph-wiggum;
      recursive = true;
    };

    # Samber marketplace registry
    ".claude/plugins/marketplaces/cc" = {
      source = "${claude-plugins-src.cc-marketplace-src}";
      recursive = true;
    };

    # Samber Go skills plugin - opt-in, load via:
    #   claude --plugin-dir ~/plugins/cc-skills-golang
    "plugins/cc-skills-golang" = {
      source = "${claude-plugins-src.cc-skills-golang-src}";
      recursive = true;
    };

    # Superpowers plugin (obra/superpowers) - opt-in, load via:
    #   claude --plugin-dir ~/plugins/superpowers
    "plugins/superpowers" = {
      source = "${claude-plugins-src.superpowers-src}";
      recursive = true;
    };

    # cmux skills (manaflow-ai/cmux) - opt-in, load via:
    #   claude --plugin-dir ~/plugins/cmux
    # Upstream is not itself a Claude plugin (no .claude-plugin/plugin.json),
    # so we point the plugin dir at its skills/ and synthesize the manifest.
    "plugins/cmux/skills" = {
      source = "${claude-plugins-src.cmux-src}/skills";
      recursive = true;
    };
    "plugins/cmux/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "cmux";
      description = "cmux end-user skills: topology/routing, workspace, settings, customization, diagnostics, browser automation, markdown viewer, and keyboard shortcuts.";
      repository = "https://github.com/manaflow-ai/cmux";
    };

    # --- Opt-in skill/plugin bundles (load via claude --plugin-dir ~/plugins/<name>) ---

    # Andrej Karpathy behavioral skills (forrestchang/andrej-karpathy-skills).
    # Self-contained plugin (.claude-plugin/plugin.json at root). Load via:
    #   claude --plugin-dir ~/plugins/andrej-karpathy-skills
    "plugins/andrej-karpathy-skills" = {
      source = "${claude-plugins-src.karpathy-skills-src}";
      recursive = true;
    };

    # Marketing skills (coreyhaines31/marketingskills) - one plugin bundling 43
    # skills. Load via:
    #   claude --plugin-dir ~/plugins/marketing-skills
    "plugins/marketing-skills" = {
      source = "${claude-plugins-src.marketing-skills-src}";
      recursive = true;
    };

    # Trail of Bits security skills (trailofbits/skills) - a marketplace of 39
    # self-contained plugins under plugins/<name>. Load an individual plugin
    # via its subdir, e.g.:
    #   claude --plugin-dir ~/plugins/trailofbits/plugins/modern-python
    "plugins/trailofbits" = {
      source = "${claude-plugins-src.trailofbits-skills-src}";
      recursive = true;
    };

    # Anthropic example skills (anthropics/skills) - curated subset. Upstream is
    # a marketplace with no root plugin.json, so synthesize one exposing just
    # the skills we want. Load via:
    #   claude --plugin-dir ~/plugins/anthropic-skills
    "plugins/anthropic-skills/skills/frontend-design" = {
      source = "${claude-plugins-src.anthropic-skills-src}/skills/frontend-design";
      recursive = true;
    };
    "plugins/anthropic-skills/skills/pdf" = {
      source = "${claude-plugins-src.anthropic-skills-src}/skills/pdf";
      recursive = true;
    };
    "plugins/anthropic-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "anthropic-skills";
      description = "Curated Anthropic example skills: frontend-design, pdf.";
      repository = "https://github.com/anthropics/skills";
    };

    # Vercel agent skills (vercel-labs/agent-skills) - curated subset. No root
    # plugin manifest upstream, so synthesize one. The vercel-react-best-practices
    # skill lives in the react-best-practices/ directory. Load via:
    #   claude --plugin-dir ~/plugins/vercel-agent-skills
    "plugins/vercel-agent-skills/skills/web-design-guidelines" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/web-design-guidelines";
      recursive = true;
    };
    "plugins/vercel-agent-skills/skills/react-best-practices" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/react-best-practices";
      recursive = true;
    };
    "plugins/vercel-agent-skills/skills/composition-patterns" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/composition-patterns";
      recursive = true;
    };
    "plugins/vercel-agent-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "vercel-agent-skills";
      description = "Curated Vercel agent skills: web-design-guidelines, vercel-react-best-practices, composition-patterns.";
      repository = "https://github.com/vercel-labs/agent-skills";
    };

    # Remotion best-practices skill (remotion-dev/skills) - no plugin manifest
    # upstream, so synthesize one around skills/remotion. Load via:
    #   claude --plugin-dir ~/plugins/remotion-skills
    "plugins/remotion-skills/skills/remotion" = {
      source = "${claude-plugins-src.remotion-skills-src}/skills/remotion";
      recursive = true;
    };
    "plugins/remotion-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "remotion-skills";
      description = "Remotion best-practices skill for React video creation.";
      repository = "https://github.com/remotion-dev/skills";
    };

    # LSP plugin (generated from claude-plugins-official + custom nil config)
    ".claude/lsp-plugin" = {
      source = lsp-plugin;
      recursive = true;
    };

    # ccstatusline config (managed here so the quota widget replicates across
    # machines). The quota widget reuses ccusage-bar — the same non-blocking
    # script that feeds the tmux bar — so both bars share one cached fetch.
    ".config/ccstatusline/settings.json".text = builtins.toJSON {
      version = 3;
      lines = [
        [
          {
            id = "1";
            type = "model";
            color = "cyan";
          }
          {
            id = "2";
            type = "separator";
          }
          {
            id = "3";
            type = "context-length";
            color = "brightBlack";
          }
          {
            id = "4";
            type = "separator";
          }
          {
            id = "5";
            type = "git-branch";
            color = "magenta";
          }
          {
            id = "6";
            type = "separator";
          }
          {
            id = "7";
            type = "git-changes";
            color = "yellow";
          }
          {
            id = "8";
            type = "separator";
          }
          {
            id = "9";
            type = "custom-command";
            color = "magenta";
            commandPath = "${ccusage-bar}";
            timeout = 3000;
            preserveColors = false;
          }
        ]
        []
        []
      ];
      flexMode = "full-minus-40";
      compactThreshold = 60;
      colorLevel = 2;
      inheritSeparatorColors = false;
      globalBold = false;
      powerline = {
        enabled = false;
        separators = [""];
        separatorInvertBackground = [false];
        startCaps = [];
        endCaps = [];
        autoAlign = false;
      };
    };

    ".claude/CLAUDE.md".text = builtins.readFile ../../../apps/claude-code/CLAUDE.md;

    ".claude/settings.json".text = builtins.toJSON {
      env = {
        DISABLE_AUTOUPDATER = "1";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        ENABLE_LSP_TOOL = "1";
      };

      statusLine = {
        type = "command";
        command = "${ccstatusline}/bin/ccstatusline";
        padding = 0;
      };

      skipDangerousModePermissionPrompt = true;

      # Push notifications (shown in /config):
      #   inputNeededNotifEnabled -> "Push when actions required"
      #   agentPushNotifEnabled   -> "Push when Claude decides"
      inputNeededNotifEnabled = true;
      agentPushNotifEnabled = true;

      permissions = {
        defaultMode = "bypassPermissions";
        allow = [];

        deny = [];
      };

      hooks = {
        Stop = [
          {
            # Ralph Wiggum stop hook - intercepts exit when loop is active
            hooks = [
              {
                type = "command";
                command = "$HOME/.claude/assets/ralph-wiggum/hooks/stop-hook.sh";
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Write|Edit|MultiEdit";
            hooks = [
              {
                command = "just format || npm run format || true";
                type = "command";
              }
            ];
          }
        ];
      };
      includeCoAuthoredBy = false;
    };
  };
}
