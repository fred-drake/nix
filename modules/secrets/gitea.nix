{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets.check-service-env = {
      sopsFile = config.secrets.host.gitea.check-service-env;
      mode = "0400";
      key = "data";
    };
  };
}
