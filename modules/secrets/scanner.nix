{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      default-ssh-key = {
        sopsFile = config.secrets.host.scanner.default-ssh-key;
        path = "/home/default/.ssh/id_ed25519";
        owner = "default";
        group = "users";
        mode = "0400";
        key = "data";
      };
    };
  };
}
