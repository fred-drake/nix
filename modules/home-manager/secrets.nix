{config, ...}: let
  home = config.home.homeDirectory;
in {
  # Configure SOPS with age key
  sops = {
    age.sshKeyPaths = ["${home}/.ssh/id_ed25519"];

    defaultSopsFile = config.secrets.sopsYaml;

    # Our secret declaration
    secrets = {
      ssh-id-rsa = {
        sopsFile = config.secrets.workstation.ssh.id_rsa;
        path = "${home}/.ssh/id_rsa";
        mode = "0400";
        key = "data";
      };

      ssh-id-ansible = {
        sopsFile = config.secrets.workstation.ssh.id_ansible;
        path = "${home}/.ssh/id_ansible";
        mode = "0400";
        key = "data";
      };

      ssh-id-infrastructure = {
        sopsFile = config.secrets.workstation.ssh.id_infrastructure;
        path = "${home}/.ssh/id_infrastructure";
        mode = "0400";
        key = "data";
      };

      git-credentials = {
        sopsFile = config.secrets.workstation.git-credentials;
        path = "${home}/.git-credentials";
        mode = "0400";
        key = "data";
      };

      continue-config = {
        sopsFile = config.secrets.workstation.continue-config;
        path = "${home}/.continue/config.json";
        mode = "0400";
        key = "data";
      };

      mc-config = {
        sopsFile = config.secrets.workstation.mc-config;
        path = "${home}/.mc/config.json";
        mode = "0400";
        key = "data";
      };

      bws = {
        sopsFile = config.secrets.workstation.bws;
        path = "${home}/.bws.env";
        mode = "0400";
        key = "data";
      };

      llm-deepseek = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "deepseek";
      };

      llm-openai = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "openai";
      };

      llm-groq = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "groq";
      };

      llm-anthropic = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "anthropic";
      };

      llm-gemini = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "gemini";
      };

      llm-sambanova = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "sambanova";
      };

      llm-openrouter = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "openrouter";
      };

      llm-brave = {
        sopsFile = config.secrets.workstation.llm-api-keys;
        mode = "0400";
        key = "brave";
      };

      docker-auth = {
        sopsFile = config.secrets.workstation.docker-auth;
        mode = "0400";
        key = "data";
        path = "${home}/.docker/config.json";
      };

      sonarqube-token = {
        sopsFile = config.secrets.workstation.sonarqube-token;
        mode = "0400";
        key = "token";
      };

      personal-gitea-token = {
        sopsFile = config.secrets.workstation.gitea-tokens;
        mode = "0400";
        key = "personal";
      };

      product-owner-gitea-token = {
        sopsFile = config.secrets.workstation.gitea-tokens;
        mode = "0400";
        key = "product-owner";
      };

      engineer-gitea-token = {
        sopsFile = config.secrets.workstation.gitea-tokens;
        mode = "0400";
        key = "engineer";
      };

      oci-config = {
        sopsFile = config.secrets.workstation.oci-config;
        mode = "400";
        key = "data";
        path = "${home}/.oci/config";
      };

      oracle-cloud-key = {
        sopsFile = config.secrets.workstation.ssh.oracle_cloud_key;
        mode = "400";
        key = "data";
        path = "${home}/.ssh/oracle_cloud_key.pem";
      };

      claude-env = {
        sopsFile = config.secrets.workstation.claude-notification-hook-env;
        mode = "400";
        key = "data";
        path = "${home}/.config/fish/conf.d/claude-env.fish";
      };
    };
  };

  # Symlink for containers runtime location
  home.file = {
    ".config/containers/auth.json".source = config.lib.file.mkOutOfStoreSymlink "${home}/.docker/config.json";
  };
}
