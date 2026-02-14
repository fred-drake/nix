{config, ...}: {
  sops = {
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      cloudflare-api-key = {
        sopsFile = config.secrets.cloudflare.letsencrypt-token;
        mode = "0400";
        key = "data";
      };
      postgresql-env = {
        sopsFile = config.secrets.host.resume.postgresql-env;
        mode = "0400";
        key = "data";
      };
      minio-env = {
        sopsFile = config.secrets.host.resume.minio-env;
        mode = "0400";
        key = "data";
      };
      chrome-env = {
        sopsFile = config.secrets.host.resume.chrome-env;
        mode = "0400";
        key = "data";
      };
      resume-env = {
        sopsFile = config.secrets.host.resume.resume-env;
        mode = "0400";
        key = "data";
      };
      woodpecker-postgresql-env = {
        sopsFile = config.secrets.host.woodpecker.postgresql-env;
        mode = "0400";
        key = "data";
      };
      woodpecker-env = {
        sopsFile = config.secrets.host.woodpecker.woodpecker-env;
        mode = "0400";
        key = "data";
      };
      woodpecker-agent-env = {
        sopsFile = config.secrets.host.woodpecker.woodpecker-agent-env;
        mode = "0400";
        key = "data";
      };
      gitea-check-service-env = {
        sopsFile = config.secrets.host.gitea.check-service-env;
        mode = "0400";
        key = "data";
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
      paperless-postgresql-env = {
        sopsFile = config.secrets.host.paperless.postgresql-env;
        mode = "0400";
        key = "data";
      };
      paperless-env = {
        sopsFile = config.secrets.host.paperless.paperless-env;
        mode = "0400";
        key = "data";
      };
      paperless-ai-env = {
        sopsFile = config.secrets.host.paperless.paperless-ai-env;
        mode = "0400";
        key = "data";
      };
    };
    templates."gitea-storage-credentials" = {
      content = ''
        username=${config.sops.placeholder."gitea-storage-username"}
        password=${config.sops.placeholder."gitea-storage-password"}
      '';
      mode = "0400";
    };
    templates."paperless-storage-credentials" = {
      content = ''
        username=${config.sops.placeholder."paperless-storage-username"}
        password=${config.sops.placeholder."paperless-storage-password"}
      '';
      mode = "0400";
    };
  };
}
