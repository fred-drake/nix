{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  realClaude = "/etc/profiles/per-user/${config.home.username}/bin/claude";

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
  actual-mcp = pkgs.callPackage ../../../apps/actual-mcp.nix {};
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
    actual-mcp # Actual Budget MCP server
    claude-usage # Claude Code usage JSON fetcher
    pkgs.uv # uvx, used to run workspace-mcp and other Python MCP servers

    # LSP servers (used by the nix-managed-lsp plugin)
    pkgs.nixd # Nix
    pkgs.pyright # Python
    pkgs.typescript-language-server # TypeScript/JavaScript
    pkgs.gopls # Go
    pkgs.rust-analyzer # Rust
    pkgs.jdt-language-server # Java
    # NOTE: sourcekit-lsp is intentionally NOT installed from nixpkgs.
    # The nixpkgs version (5.10.1) is too old for Swift 6.x projects.
    # /usr/bin/sourcekit-lsp is a macOS shim that delegates to the active
    # Xcode toolchain (Swift 6.3+). Both pi-lsp and Claude Code reference
    # it by absolute path so Nix PATH ordering cannot shadow it.
  ];

  # SOPS templates for MCP configuration
  sops.templates = {
    mcp-actual = {
      mode = "0400";
      path = "${home}/mcp/actual.json";
      content = builtins.toJSON {
        mcpServers = {
          actual = {
            command = "${actual-mcp}/bin/actual-mcp";
            args = ["--enable-write"];
            env = {
              ACTUAL_SERVER_URL = "https://actual.internal.freddrake.com";
              ACTUAL_BUDGET_SYNC_ID = "0da0a210-9782-4137-ad4a-4b6ec2edb08b";
              ACTUAL_PASSWORD = config.sops.placeholder.actual-password;
            };
          };
          chrome = {
            command = "npx";
            args = ["-y" "chrome-devtools-mcp@latest" "--browserUrl=http://127.0.0.1:9222"];
          };
        };
      };
    };

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

    mcp-paperless = {
      mode = "0400";
      path = "${home}/mcp/paperless.json";
      content = builtins.toJSON {
        mcpServers = {
          paperless = {
            command = "npx";
            args = [
              "-y"
              "@baruchiro/paperless-mcp"
              "--baseUrl"
              "https://paperless.${config.soft-secrets.networking.domain}"
              "--token"
              config.sops.placeholder.paperless-mcp-api-key
            ];
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
            args = ["--with" "aiofile<3.10" "workspace-mcp" "--tools" "gmail" "drive" "docs"];
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
    mcp-genki = {
      mode = "0400";
      path = "${home}/mcp/genki.json";
      content = builtins.toJSON {
        mcpServers = {
          genki = {
            type = "http";
            url = "https://api.genki.world/mcp";
          };
        };
      };
    };
  };

  # Claude Code configuration files
  home.file = {
    ".local/bin/claude".source = config.lib.file.mkOutOfStoreSymlink realClaude;

    # Agent-agnostic command files (shared via apps/agent-common)
    ".claude/commands" = {
      source = ../../../apps/agent-common/commands;
      recursive = true;
    };

    ".claude/agents" = {
      source = ../../../apps/agent-common/agents;
      recursive = true;
    };

    # Saved Workflow scripts; each *.js becomes a /<name> workflow command
    ".claude/workflows" = {
      source = ../../../apps/agent-common/workflows;
      recursive = true;
    };

    ".claude/skills" = {
      source = ../../../apps/agent-common/skills;
      recursive = true;
    };

    # Samber marketplace registry
    ".claude/plugins/marketplaces/cc" = {
      source = "${claude-plugins-src.cc-marketplace-src}";
      recursive = true;
    };

    # Samber Go skills plugin - opt-in, load via:
    #   claude --plugin-dir ~/skills/all/cc-skills-golang
    "skills/all/cc-skills-golang" = {
      source = "${claude-plugins-src.cc-skills-golang-src}";
      recursive = true;
    };

    # Superpowers plugin (obra/superpowers) - opt-in, load via:
    #   claude --plugin-dir ~/skills/all/superpowers
    "skills/all/superpowers" = {
      source = "${claude-plugins-src.superpowers-src}";
      recursive = true;
    };

    # --- Opt-in skill/plugin bundles (load via claude --plugin-dir ~/skills/all/<name>) ---

    # Andrej Karpathy behavioral skills (forrestchang/andrej-karpathy-skills).
    # Self-contained plugin (.claude-plugin/plugin.json at root). Load via:
    #   claude --plugin-dir ~/skills/all/andrej-karpathy-skills
    "skills/all/andrej-karpathy-skills" = {
      source = "${claude-plugins-src.karpathy-skills-src}";
      recursive = true;
    };

    # Netresearch AGENTS.md generator skill. Self-contained plugin; pi also
    # loads this through modules/home-manager/features/pi.nix skills.
    "skills/all/agent-rules-skill" = {
      source = "${claude-plugins-src.agent-rules-skill-src}";
      recursive = true;
    };

    # herdr agent skill (ogulcancelik/herdr). Wrap the reusable skill under
    # skills/herdr so pi loads only the user-facing herdr control skill, not the
    # repo's maintenance skills.
    "skills/all/herdr/skills/herdr/SKILL.md" = {
      source = "${claude-plugins-src.herdr-src}/skills/herdr/SKILL.md";
    };
    "skills/all/herdr/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "herdr";
      description = "Control herdr from inside herdr: manage workspaces, tabs, panes, agents, output reads, and state waits.";
      repository = "https://github.com/ogulcancelik/herdr";
    };

    # Marketing skills (coreyhaines31/marketingskills) - one plugin bundling 43
    # skills. Load via:
    #   claude --plugin-dir ~/skills/all/marketing-skills
    "skills/all/marketing-skills" = {
      source = "${claude-plugins-src.marketing-skills-src}";
      recursive = true;
    };

    # Variate skills (Nutlope/variate).
    "skills/all/variate" = {
      source = "${claude-plugins-src.variate-src}";
      recursive = true;
    };

    # Slavingia skills (slavingia/skills).
    "skills/all/slavingia-skills" = {
      source = "${claude-plugins-src.slavingia-skills-src}";
      recursive = true;
    };

    # Trail of Bits security skills (trailofbits/skills) - a marketplace of 39
    # self-contained plugins under plugins/<name>. Load an individual plugin
    # via its subdir, e.g.:
    #   claude --plugin-dir ~/skills/all/trailofbits/plugins/modern-python
    "skills/all/trailofbits" = {
      source = "${claude-plugins-src.trailofbits-skills-src}";
      recursive = true;
    };

    # Anthropic example skills (anthropics/skills) - curated subset. Upstream is
    # a marketplace with no root plugin.json, so synthesize one exposing just
    # the skills we want. Load via:
    #   claude --plugin-dir ~/skills/all/anthropic-skills
    "skills/all/anthropic-skills/skills/frontend-design" = {
      source = "${claude-plugins-src.anthropic-skills-src}/skills/frontend-design";
      recursive = true;
    };
    "skills/all/anthropic-skills/skills/pdf" = {
      source = "${claude-plugins-src.anthropic-skills-src}/skills/pdf";
      recursive = true;
    };
    "skills/all/anthropic-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "anthropic-skills";
      description = "Curated Anthropic example skills: frontend-design, pdf.";
      repository = "https://github.com/anthropics/skills";
    };

    # Vercel agent skills (vercel-labs/agent-skills) - curated subset. No root
    # plugin manifest upstream, so synthesize one. The vercel-react-best-practices
    # skill lives in the react-best-practices/ directory. Load via:
    #   claude --plugin-dir ~/skills/all/vercel-agent-skills
    "skills/all/vercel-agent-skills/skills/web-design-guidelines" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/web-design-guidelines";
      recursive = true;
    };
    "skills/all/vercel-agent-skills/skills/react-best-practices" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/react-best-practices";
      recursive = true;
    };
    "skills/all/vercel-agent-skills/skills/composition-patterns" = {
      source = "${claude-plugins-src.vercel-agent-skills-src}/skills/composition-patterns";
      recursive = true;
    };
    "skills/all/vercel-agent-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
      name = "vercel-agent-skills";
      description = "Curated Vercel agent skills: web-design-guidelines, vercel-react-best-practices, composition-patterns.";
      repository = "https://github.com/vercel-labs/agent-skills";
    };

    # Remotion best-practices skill (remotion-dev/skills) - no plugin manifest
    # upstream, so synthesize one around skills/remotion-best-practices. Load via:
    #   claude --plugin-dir ~/skills/all/remotion-skills
    "skills/all/remotion-skills/skills/remotion" = {
      source = "${claude-plugins-src.remotion-skills-src}/skills/remotion-best-practices";
      recursive = true;
    };
    "skills/all/remotion-skills/.claude-plugin/plugin.json".text = builtins.toJSON {
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
            # Count of untracked files (respects .gitignore) — renders "?:N",
            # the equivalent of the "?N" hint in the fish prompt.
            id = "9";
            type = "git-untracked-files";
            color = "brightBlue";
          }
          {
            id = "10";
            type = "separator";
          }
          {
            id = "11";
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

    # Generic agent instructions live in apps/agent-common/AGENTS.md; the same
    # source is surfaced to Claude Code as ~/.claude/CLAUDE.md.
    ".claude/CLAUDE.md".text = builtins.readFile ../../../apps/agent-common/AGENTS.md;

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

      # Terminal UI renderer. "fullscreen" = flicker-free alt-screen renderer
      # with virtualized scrollback + mouse support (equivalent to
      # CLAUDE_CODE_NO_FLICKER=1). Setting this also suppresses the one-time
      # "Try the new fullscreen renderer?" upsell prompt, which otherwise can't
      # persist its answer because settings.json is a read-only nix symlink.
      tui = "fullscreen";

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
