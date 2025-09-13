{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  claude-code = pkgs.callPackage ../../apps/claude-code {};
  gitea-mcp = pkgs.callPackage ../../apps/gitea-mcp.nix {};
  ccstatusline = pkgs.callPackage ../../apps/ccstatusline.nix {
    npm-packages = import ../../apps/fetcher/npm-packages.nix;
  };
in {
  # Add Claude Code and Gitea MCP packages
  home.packages = [
    claude-code # Claude Code CLI tool
    gitea-mcp # Gitea MCP server
  ];

  # SOPS templates for MCP configuration
  sops.templates = {
    mcp-browsermcp = {
      mode = "0400";
      path = "${home}/mcp/browsermcp.json";
      content = builtins.toJSON {
        mcpServers = {
          browsermcp = {
            command = "npx";
            args = ["@browsermcp/mcp@latest"];
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
    mcp-sonarqube = {
      mode = "0400";
      path = "${home}/mcp/sonarqube.json";
      content = builtins.toJSON {
        mcpServers = {
          sonarqube = {
            command = "podman";
            args = ["run" "-i" "--rm" "-e" "SONARQUBE_TOKEN" "-e" "SONARQUBE_URL" "-e" "TELEMETRY_DISABLED" "mcp/sonarqube"];
            env = {
              SONARQUBE_URL = "https://sonarqube.${config.soft-secrets.networking.domain}";
              SONARQUBE_TOKEN = config.sops.placeholder.sonarqube-token;
              TELEMETRY_DISABLED = "true";
            };
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
          gitea-personal = {
            command = "gitea-mcp";
            args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
            env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.personal-gitea-token;};
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
    # mcp-ref = {
    #
    # }
  };

  # Claude Code configuration files
  home.file = {
    # Claude command files
    ".claude/commands" = {
      source = ../../apps/claude-code/commands;
      recursive = true;
    };

    ".claude/agents" = {
      source = ../../apps/claude-code/agents;
      recursive = true;
    };

    ".claude/CLAUDE.md".text = builtins.readFile ../../apps/claude-code/CLAUDE.md;

    ".claude/settings.json".text = builtins.toJSON {
      statusLine = {
        type = "command";
        command = "${ccstatusline}/bin/ccstatusline";
        padding = 0;
      };

      permissions = {
        allow = [];

        deny = [];
      };

      hooks = {
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "tdd-guard";
              }
            ];
          }
        ];
        SessionStart = [
          {
            matcher = "startup|resume|clear";
            hooks = [
              {
                type = "command";
                command = "tdd-guard";
              }
            ];
          }
        ];
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                command = "PROJECT_NAME=\${PROJECT_ROOT##*/}; PROJECT_NAME=\${PROJECT_NAME:-'project'}; curl -X POST -H 'Content-type: application/json' --data \"{\\\"text\\\":\\\"Task completed in $PROJECT_NAME\\\"}\" \"$CLAUDE_NOTIFICATION_SLACK_URL\"";
                type = "command";
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
      env = {
      };
    };
  };
}
