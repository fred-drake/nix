{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
in {
  # Workaround for sops-nix LaunchAgent having empty PATH on macOS
  # The LaunchAgent needs /usr/bin in PATH to find 'getconf' for DARWIN_USER_TEMP_DIR
  launchd.agents.sops-nix = lib.mkIf pkgs.stdenv.isDarwin {
    config = {
      EnvironmentVariables.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
    };
  };

  # Configure SOPS with age key
  sops = {
    age.sshKeyPaths = ["${home}/.ssh/id_ed25519"];

    defaultSopsFile = config.secrets.sopsYaml;

    # Our secret declaration
    secrets = {
      ssh-id-rsa = {
        sopsFile = config.secrets.workstation.identity.ssh.id_rsa;
        path = "${home}/.ssh/id_rsa";
        mode = "0400";
        key = "data";
      };

      ssh-id-ansible = {
        sopsFile = config.secrets.workstation.identity.ssh.id_ansible;
        path = "${home}/.ssh/id_ansible";
        mode = "0400";
        key = "data";
      };

      ssh-id-infrastructure = {
        sopsFile = config.secrets.workstation.identity.ssh.id_infrastructure;
        path = "${home}/.ssh/id_infrastructure";
        mode = "0400";
        key = "data";
      };

      git-credentials = {
        sopsFile = config.secrets.workstation.identity.git-credentials;
        path = "${home}/.git-credentials";
        mode = "0400";
        key = "data";
      };

      continue-config = {
        sopsFile = config.secrets.workstation.tools.continue-config;
        path = "${home}/.continue/config.json";
        mode = "0400";
        key = "data";
      };

      mc-config = {
        sopsFile = config.secrets.workstation.tools.mc-config;
        path = "${home}/.mc/config.json";
        mode = "0400";
        key = "data";
      };

      bws = {
        sopsFile = config.secrets.workstation.tools.bws;
        path = "${home}/.bws.env";
        mode = "0400";
        key = "data";
      };

      llm-deepseek = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "deepseek";
      };

      llm-openai = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "openai";
      };

      llm-groq = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "groq";
      };

      llm-anthropic = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "anthropic";
      };

      llm-gemini = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "gemini";
      };

      llm-sambanova = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "sambanova";
      };

      llm-openrouter = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "openrouter";
      };

      llm-brave = {
        sopsFile = config.secrets.workstation.llm.api-keys;
        mode = "0400";
        key = "brave";
      };

      docker-auth = {
        sopsFile = config.secrets.workstation.tools.docker-auth;
        mode = "0400";
        key = "data";
        path = "${home}/.docker/config.json";
      };

      personal-gitea-token = {
        sopsFile = config.secrets.workstation.identity.gitea-tokens;
        mode = "0400";
        key = "personal";
      };

      product-owner-gitea-token = {
        sopsFile = config.secrets.workstation.identity.gitea-tokens;
        mode = "0400";
        key = "product-owner";
      };

      engineer-gitea-token = {
        sopsFile = config.secrets.workstation.identity.gitea-tokens;
        mode = "0400";
        key = "engineer";
      };

      code-architect-gitea-token = {
        sopsFile = config.secrets.workstation.identity.gitea-tokens;
        mode = "0400";
        key = "code-architect";
      };

      reviewer-gitea-token = {
        sopsFile = config.secrets.workstation.identity.gitea-tokens;
        mode = "0400";
        key = "reviewer";
      };

      github-token = {
        sopsFile = config.secrets.workstation.identity.github-token;
        mode = "0400";
        key = "token";
      };

      oci-config = {
        sopsFile = config.secrets.workstation.cloud.oci-config;
        mode = "0400";
        key = "data";
        path = "${home}/.oci/config";
      };

      oracle-cloud-key = {
        sopsFile = config.secrets.workstation.identity.ssh.oracle_cloud_key;
        mode = "0400";
        key = "data";
        path = "${home}/.ssh/oracle_cloud_key.pem";
      };

      ref-mcp-api-key = {
        sopsFile = config.secrets.workstation.mcp.ref-mcp;
        mode = "0400";
        key = "api-key";
      };

      firecrawl-api-key = {
        sopsFile = config.secrets.workstation.mcp.firecrawl;
        mode = "0400";
        key = "api-key";
      };

      stripe-sandbox-api-key = {
        sopsFile = config.secrets.workstation.mcp.stripe;
        mode = "0400";
        key = "sandbox";
      };

      trello-legacy-api-key = {
        sopsFile = config.secrets.workstation.mcp.trello;
        mode = "0400";
        key = "legacy-api-key";
      };

      trello-legacy-api-token = {
        sopsFile = config.secrets.workstation.mcp.trello;
        mode = "0400";
        key = "legacy-api-token";
      };

      google-service-account = {
        sopsFile = config.secrets.workstation.cloud.google-service-account;
        mode = "0400";
        key = "data";
      };

      google-oauth = {
        sopsFile = config.secrets.workstation.cloud.google-oauth;
        mode = "0400";
        key = "data";
      };

      google-workspace-client-id = {
        sopsFile = config.secrets.workstation.cloud.google-workstation;
        mode = "0400";
        key = "client-id";
      };

      google-workspace-client-secret = {
        sopsFile = config.secrets.workstation.cloud.google-workstation;
        mode = "0400";
        key = "client-secret";
      };

      zohomail-mcp-url = {
        sopsFile = config.secrets.workstation.mcp.zohomail;
        mode = "0400";
        key = "mcp-url";
      };

      zohomail-client-id = {
        sopsFile = config.secrets.workstation.mcp.zohomail;
        mode = "0400";
        key = "client-id";
      };

      zohomail-client-secret = {
        sopsFile = config.secrets.workstation.mcp.zohomail;
        mode = "0400";
        key = "client-secret";
      };

      resume-api-key = {
        sopsFile = config.secrets.workstation.projects.resume.credentials;
        mode = "0400";
        key = "api-key";
      };

      woodpecker-credentials = {
        sopsFile = config.secrets.workstation.tools.woodpecker-env;
        mode = "0400";
        key = "data";
        path = "${home}/.config/fish/conf.d/woodpecker-env.fish";
      };

      icloud-bridge-api-key = {
        sopsFile = config.secrets.workstation.tools.icloud-bridge;
        mode = "0400";
        key = "api-key";
      };

      dalaran-username = {
        sopsFile = config.secrets.switch.dalaran.credentials;
        mode = "0400";
        key = "username";
      };

      dalaran-password = {
        sopsFile = config.secrets.switch.dalaran.credentials;
        mode = "0400";
        key = "password";
      };

      karazhan-username = {
        sopsFile = config.secrets.router.karazhan.credentials;
        mode = "0400";
        key = "username";
      };

      karazhan-password = {
        sopsFile = config.secrets.router.karazhan.credentials;
        mode = "0400";
        key = "password";
      };

      karazhan-tailscale-auth = {
        sopsFile = config.secrets.router.karazhan.credentials;
        mode = "0400";
        key = "tailscale-auth";
      };

      hetzner-home-api-token = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "api-token";
      };

      hetzner-home-storage-box-password = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "storage-box-password";
      };

      hetzner-restic-password = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "restic-password";
      };

      hetzner-borg-passphrase = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "borg-password";
      };

      brainrush-terraform-prod-api-token = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "brainrush-terraform-prod-api-token";
      };

      brainrush-terraform-s3-access-key = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "brainrush-terraform-s3-access-key";
      };

      brainrush-terraform-s3-secret-key = {
        sopsFile = config.secrets.workstation.cloud.hetzner-home;
        mode = "0400";
        key = "brainrush-terraform-s3-secret-key";
      };

      cloudflare-api-key = {
        sopsFile = config.secrets.workstation.cloud.cloudflare;
        mode = "0400";
        key = "api-key";
      };

      cloudflare-account-id = {
        sopsFile = config.secrets.workstation.cloud.cloudflare;
        mode = "0400";
        key = "account-id";
      };

      cloudflare-r2-access-key = {
        sopsFile = config.secrets.workstation.cloud.cloudflare;
        mode = "0400";
        key = "r2-access-key";
      };

      cloudflare-r2-secret-key = {
        sopsFile = config.secrets.workstation.cloud.cloudflare;
        mode = "0400";
        key = "r2-secret-key";
      };

      gitea-storage-username = {
        sopsFile = config.secrets.host.ironforge.gitea-storage;
        mode = "0400";
        key = "username";
      };

      gitea-storage-password = {
        sopsFile = config.secrets.host.ironforge.gitea-storage;
        mode = "0400";
        key = "password";
      };

      videos-storage-username = {
        sopsFile = config.secrets.host.ironforge.videos-storage;
        mode = "0400";
        key = "username";
      };

      videos-storage-password = {
        sopsFile = config.secrets.host.ironforge.videos-storage;
        mode = "0400";
        key = "password";
      };

      calibre-storage-username = {
        sopsFile = config.secrets.host.ironforge.calibre-storage;
        mode = "0400";
        key = "username";
      };

      calibre-storage-password = {
        sopsFile = config.secrets.host.ironforge.calibre-storage;
        mode = "0400";
        key = "password";
      };

      downloads-storage-username = {
        sopsFile = config.secrets.host.ironforge.downloads-storage;
        mode = "0400";
        key = "username";
      };

      downloads-storage-password = {
        sopsFile = config.secrets.host.ironforge.downloads-storage;
        mode = "0400";
        key = "password";
      };

      paperless-storage-username = {
        sopsFile = config.secrets.host.ironforge.paperless-storage;
        mode = "0400";
        key = "username";
      };

      paperless-storage-password = {
        sopsFile = config.secrets.host.ironforge.paperless-storage;
        mode = "0400";
        key = "password";
      };

      telegram-api-key = {
        sopsFile = config.secrets.workstation.mcp.telegram;
        mode = "0400";
        key = "api-key";
        path = "${home}/.carapace/credentials/plugins/telegram/bot-token";
      };

      emulation-storage-username = {
        sopsFile = config.secrets.host.ironforge.emulation-storage;
        mode = "0400";
        key = "username";
      };

      emulation-storage-password = {
        sopsFile = config.secrets.host.ironforge.emulation-storage;
        mode = "0400";
        key = "password";
      };

      nintendopower-storage-username = {
        sopsFile = config.secrets.host.ironforge.nintendopower-storage;
        mode = "0400";
        key = "username";
      };

      nintendopower-storage-password = {
        sopsFile = config.secrets.host.ironforge.nintendopower-storage;
        mode = "0400";
        key = "password";
      };

      wowclient-storage-username = {
        sopsFile = config.secrets.host.ironforge.wowclient-storage;
        mode = "0400";
        key = "username";
      };

      wowclient-storage-password = {
        sopsFile = config.secrets.host.ironforge.wowclient-storage;
        mode = "0400";
        key = "password";
      };

      fredbox-storage-username = {
        sopsFile = config.secrets.host.ironforge.fredbox-storage;
        mode = "0400";
        key = "username";
      };

      fredbox-storage-password = {
        sopsFile = config.secrets.host.ironforge.fredbox-storage;
        mode = "0400";
        key = "password";
      };

      silvermoon-password = {
        sopsFile = config.secrets.switch.silvermoon.credentials;
        mode = "0400";
        key = "password";
      };

      hearthstone-password = {
        sopsFile = config.secrets.router.hearthstone.credentials;
        mode = "0400";
        key = "password";
      };

      hearthstone-tailscale-auth = {
        sopsFile = config.secrets.router.hearthstone.credentials;
        mode = "0400";
        key = "tailscale-auth";
      };

      hearthstone-wifi-main-key = {
        sopsFile = config.secrets.router.hearthstone.credentials;
        mode = "0400";
        key = "wifi-main-key";
      };

      hearthstone-wifi-guest-key = {
        sopsFile = config.secrets.router.hearthstone.credentials;
        mode = "0400";
        key = "wifi-guest-key";
      };

      hearthstone-wifi-mlo-key = {
        sopsFile = config.secrets.router.hearthstone.credentials;
        mode = "0400";
        key = "wifi-mlo-key";
      };

      apple-app-store-issuer-id = {
        sopsFile = config.secrets.workstation.ios-signing.apple-app-store;
        mode = "0400";
        key = "issuer-id";
      };

      apple-app-store-thrifter-local-upload-key-id = {
        sopsFile = config.secrets.workstation.ios-signing.apple-app-store;
        mode = "0400";
        key = "thrifter-local-upload-key-id";
      };

      apple-app-store-thrifter-local-upload-keyfile = {
        sopsFile = config.secrets.workstation.ios-signing.apple-app-store;
        mode = "0600";
        key = "thrifter-local-upload-keyfile";
        path = "${home}/.appstoreconnect/private_keys/AuthKey_L32H7BU6AQ.p8";
      };

      thrifter-prod-db-url = {
        sopsFile = config.secrets.workstation.projects.thrifter.prod-db-url;
        mode = "0400";
        key = "data";
      };

      thrifter-local-api-key = {
        sopsFile = config.secrets.workstation.projects.thrifter.local;
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
