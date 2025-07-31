{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  claude-code = pkgs.callPackage ../../apps/claude-code {};
  gitea-mcp = pkgs.callPackage ../../apps/gitea-mcp.nix {};
in {
  # Add Claude Code and Gitea MCP packages
  home.packages = [
    claude-code # Claude Code CLI tool
    gitea-mcp # Gitea MCP server
  ];

  # SOPS template for MCP configuration
  sops.templates."mcp-config" = {
    mode = "0400";
    path = "${home}/mcp-config.json";
    content = builtins.toJSON {
      mcpServers = {
        brave-search = {
          command = "npx";
          args = ["-y" "@modelcontextprotocol/server-brave-search"];
          env = {"BRAVE_API_KEY" = config.sops.placeholder.llm-brave;};
        };
        playwright = {
          command = "npx";
          args = ["@playwright/mcp@latest"];
        };
        context7 = {
          command = "npx";
          args = ["-y" "@upstash/context7-mcp"];
        };
        sonarqube = {
          command = "podman";
          args = ["run" "-i" "--rm" "-e" "SONARQUBE_TOKEN" "-e" "SONARQUBE_URL" "-e" "TELEMETRY_DISABLED" "mcp/sonarqube"];
          env = {
            SONARQUBE_URL = "https://sonarqube.${config.soft-secrets.networking.domain}";
            SONARQUBE_TOKEN = config.sops.placeholder.sonarqube-token;
            TELEMETRY_DISABLED = "true";
          };
        };
        gitea-personal = {
          command = "gitea-mcp";
          args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
          env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.personal-gitea-token;};
        };
        gitea-engineer = {
          command = "gitea-mcp";
          args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
          env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.engineer-gitea-token;};
        };
        gitea-product-owner = {
          command = "gitea-mcp";
          args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
          env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.product-owner-gitea-token;};
        };
      };
      gitea-code-architect = {
        command = "gitea-mcp";
        args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
        env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.code-architect-gitea-token;};
      };
      gitea-reviewer = {
        command = "gitea-mcp";
        args = ["-t" "stdio" "--host" "https://gitea.${config.soft-secrets.networking.domain}"];
        env = {GITEA_ACCESS_TOKEN = config.sops.placeholder.reviewer-gitea-token;};
      };
      github = {
        command = "podman";
        args = ["run" "-i" "--rm" "-e" "GITHUB_PERSONAL_ACCESS_TOKEN" "ghcr.io/github/github-mcp-server"];
        env = {GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.placeholder.github-token;};
      };
    };
  };

  # Claude Code configuration files
  home.file =
    {
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
        permissions = {
          allow = [
            "Bash"
            "Write"
            "MultiEdit"
            "Edit"
            "WebFetch"

            # mcp commands
            "mcp__brave-search__brave_web_search"
            "mcp__context7__resolve-library-id"
            "mcp__context7__get-library-docs"
            "context7:*"
          ];

          deny = [];
        };

        hooks = {
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

        # Claude adds this -- setting it to the year 2035 to see if it will prevent showing again
        feedbackSurveyState.lastShownTime = 2069451551000;
      };

      # MCP configuration symlinks
      ".cursor/mcp.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;
      ".codeium/windsurf/mcp_config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;

      ".config/llminate/config.yml".text = builtins.toJSON {
        mcp-config = "~/mcp-config.json";
        labels-prompt = "issue-labels";
        stop-label = "waiting-for-user";
        prompts = [
          {
            label = "user-stories";
            prompt = "llminate-user-stories";
          }
          {
            label = "architecture-review";
            prompt = "llminate-architecture-review";
          }
          {
            label = "user-test-generation";
            prompt = "llminate-user-test-generation";
          }
          {
            label = "in-development";
            prompt = "llminate-in-development";
          }
          {
            label = "needs-code-review";
            prompt = "llminate-needs-code-review";
          }
        ];
      };
    }
    // (
      if pkgs.stdenv.isDarwin
      then {
        "Library/Application Support/Claude/claude_desktop_config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;
      }
      else {}
    );
}
