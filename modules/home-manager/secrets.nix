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

      code-architect-gitea-token = {
        sopsFile = config.secrets.workstation.gitea-tokens;
        mode = "0400";
        key = "code-architect";
      };

      reviewer-gitea-token = {
        sopsFile = config.secrets.workstation.gitea-tokens;
        mode = "0400";
        key = "reviewer";
      };

      github-token = {
        sopsFile = config.secrets.workstation.github-token;
        mode = "0400";
        key = "token";
      };

      oci-config = {
        sopsFile = config.secrets.workstation.oci-config;
        mode = "0400";
        key = "data";
        path = "${home}/.oci/config";
      };

      oracle-cloud-key = {
        sopsFile = config.secrets.workstation.ssh.oracle_cloud_key;
        mode = "0400";
        key = "data";
        path = "${home}/.ssh/oracle_cloud_key.pem";
      };

      claude-env = {
        sopsFile = config.secrets.workstation.claude-notification-hook-env;
        mode = "0400";
        key = "data";
        path = "${home}/.config/fish/conf.d/claude-env.fish";
      };

      ref-mcp-api-key = {
        sopsFile = config.secrets.workstation.ref-mcp;
        mode = "0400";
        key = "api-key";
      };

      firecrawl-api-key = {
        sopsFile = config.secrets.workstation.firecrawl;
        mode = "0400";
        key = "api-key";
      };

      stripe-sandbox-api-key = {
        sopsFile = config.secrets.workstation.stripe;
        mode = "0400";
        key = "sandbox";
      };

      google-service-account = {
        sopsFile = config.secrets.workstation.google-service-account;
        mode = "0400";
        key = "data";
      };

      google-oauth = {
        sopsFile = config.secrets.workstation.google-oauth;
        mode = "0400";
        key = "data";
      };

      zohomail-mcp-url = {
        sopsFile = config.secrets.workstation.zohomail;
        mode = "0400";
        key = "mcp-url";
      };

      zohomail-client-id = {
        sopsFile = config.secrets.workstation.zohomail;
        mode = "0400";
        key = "client-id";
      };

      zohomail-client-secret = {
        sopsFile = config.secrets.workstation.zohomail;
        mode = "0400";
        key = "client-secret";
      };

      resume-credentials = {
        sopsFile = config.secrets.workstation.resume-credentials;
        mode = "0400";
        key = "data";
      };

      woodpecker-credentials = {
        sopsFile = config.secrets.workstation.woodpecker-env;
        mode = "0400";
        key = "data";
        path = "${home}/.config/fish/conf.d/woodpecker-env.fish";
      };

      icloud-bridge-api-key = {
        sopsFile = config.secrets.workstation.icloud-bridge;
        mode = "0400";
        key = "api-key";
      };
    };
  };

  # Symlink for containers runtime location
  home.file = {
    ".config/containers/auth.json".source = config.lib.file.mkOutOfStoreSymlink "${home}/.docker/config.json";
  };
}
