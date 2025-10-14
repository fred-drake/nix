{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
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
  };
}
