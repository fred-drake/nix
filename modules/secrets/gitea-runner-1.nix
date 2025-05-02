{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.gitea-registration-token = {
    sopsFile = config.secrets.host.gitea.registration-token;
    mode = "0400";
    key = "data";
  };
}
