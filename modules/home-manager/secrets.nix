{config, ...}: let
  home = config.home.homeDirectory;
in {
  # Configure SOPS with age key
  sops.age.sshKeyPaths = ["${home}/.ssh/id_ed25519"];

  sops.defaultSopsFile = config.secrets.sopsYaml;

  # Our secret declaration
  sops.secrets.ssh-id-rsa = {
    sopsFile = config.secrets.workstation.ssh.id_rsa;
    path = "${home}/.ssh/id_rsa";
    mode = "0400";
    key = "data";
  };

  sops.secrets.ssh-id-ansible = {
    sopsFile = config.secrets.workstation.ssh.id_ansible;
    path = "${home}/.ssh/id_ansible";
    mode = "0400";
    key = "data";
  };

  sops.secrets.ssh-id-infrastructure = {
    sopsFile = config.secrets.workstation.ssh.id_infrastructure;
    path = "${home}/.ssh/id_infrastructure";
    mode = "0400";
    key = "data";
  };

  sops.secrets.git-credentials = {
    sopsFile = config.secrets.workstation.git-credentials;
    path = "${home}/.git-credentials";
    mode = "0400";
    key = "data";
  };

  sops.secrets.continue-config = {
    sopsFile = config.secrets.workstation.continue-config;
    path = "${home}/.continue/config.json";
    mode = "0400";
    key = "data";
  };

  sops.secrets.mc-config = {
    sopsFile = config.secrets.workstation.mc-config;
    path = "${home}/.mc/config.json";
    mode = "0400";
    key = "data";
  };

  sops.secrets.bws = {
    sopsFile = config.secrets.workstation.bws;
    path = "${home}/.bws.env";
    mode = "0400";
    key = "data";
  };

  sops.secrets.llm-deepseek = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "deepseek";
  };

  sops.secrets.llm-openai = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "openai";
  };

  sops.secrets.llm-groq = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "groq";
  };

  sops.secrets.llm-anthropic = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "anthropic";
  };

  sops.secrets.llm-gemini = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "gemini";
  };

  sops.secrets.llm-sambanova = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "sambanova";
  };

  sops.secrets.llm-openrouter = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "openrouter";
  };

  sops.secrets.llm-brave = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "brave";
  };

  sops.secrets.docker-auth = {
    sopsFile = config.secrets.workstation.docker-auth;
    mode = "0400";
    key = "data";
    path = "${home}/.docker/config.json";
  };

  # Symlink for containers runtime location
  home.file.".config/containers/auth.json".source = config.lib.file.mkOutOfStoreSymlink "${home}/.docker/config.json";

  sops.templates."mcp-config" = {
    mode = "0400";
    path = "${home}/mcp-config.json";
    content = ''
      {
        "mcpServers": {
          "brave-search": {
            "command": "npx",
            "args": [
              "-y",
              "@modelcontextprotocol/server-brave-search"
            ],
            "env": {
              "BRAVE_API_KEY": "${config.sops.placeholder.llm-brave}"
            }
          },
          "playwright": {
            "command": "npx",
            "args": [
              "@playwright/mcp@latest"
            ]
          },
          "context7": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"]
          }
        }
      }
    '';
  };
  home.file.".cursor/mcp.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;
  home.file.".codeium/windsurf/mcp_config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;
  home.file."Library/Application Support/Claude/claude_desktop_config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.mcp-config.path;

  sops.secrets.oci-config = {
    sopsFile = config.secrets.workstation.oci-config;
    mode = "400";
    key = "data";
    path = "${home}/.oci/config";
  };

  sops.secrets.oracle-cloud-key = {
    sopsFile = config.secrets.workstation.ssh.oracle_cloud_key;
    mode = "400";
    key = "data";
    path = "${home}/.ssh/oracle_cloud_key.pem";
  };

  sops.secrets.claude-env = {
    sopsFile = config.secrets.workstation.claude-notification-hook-env;
    mode = "400";
    key = "data";
    path = "${home}/.config/fish/conf.d/claude-env.fish";
  };
}
