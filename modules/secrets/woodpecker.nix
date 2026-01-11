{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      postgresql-env = {
        sopsFile = config.secrets.host.woodpecker.postgresql-env;
        mode = "0400";
        key = "data";
      };
      woodpecker-env = {
        sopsFile = config.secrets.host.woodpecker.woodpecker-env;
        mode = "0400";
        key = "data";
      };
    };
  };
}
