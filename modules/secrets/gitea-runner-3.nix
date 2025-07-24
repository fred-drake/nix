{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets.gitea-registration-token = {
      sopsFile = config.secrets.host.gitea.registration-token;
      mode = "0400";
      key = "data";
    };
  };
}
