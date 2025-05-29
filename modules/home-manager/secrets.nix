{config, ...}: let
  home = config.home.homeDirectory;
in {
  # Configure SOPS with age key
  sops.age.sshKeyPaths = ["${home}/.ssh/id_ed25519"];

  sops.defaultSopsFile = config.secrets.sopsYaml;

  # Our secret declaration
  sops.secrets.ssh-id-rsa = {
    sopsFile = config.secrets.workstation.ssh.id_rsa;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_rsa".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-rsa.path;

  sops.secrets.ssh-id-ansible = {
    sopsFile = config.secrets.workstation.ssh.id_ansible;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_ansible".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-ansible.path;

  sops.secrets.ssh-id-infrastructure = {
    sopsFile = config.secrets.workstation.ssh.id_infrastructure;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_infrastructure".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-infrastructure.path;

  sops.secrets.git-credentials = {
    sopsFile = config.secrets.workstation.git-credentials;
    mode = "0400";
    key = "data";
  };
  home.file.".git-credentials".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.git-credentials.path;

  sops.secrets.continue-config = {
    sopsFile = config.secrets.workstation.continue-config;
    mode = "0400";
    key = "data";
  };
  home.file.".continue/config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.continue-config.path;

  sops.secrets.bws = {
    sopsFile = config.secrets.workstation.bws;
    mode = "0400";
    key = "data";
  };
  home.file.".bws.env".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.bws.path;

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
}
