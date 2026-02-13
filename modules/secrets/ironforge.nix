{config, ...}: {
  sops = {
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      cloudflare-api-key = {
        sopsFile = config.secrets.cloudflare.letsencrypt-token;
        mode = "0400";
        key = "data";
      };
      minio-env-file = {
        sopsFile = config.secrets.host.minio.minio-env-file;
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
    };
  };
}
