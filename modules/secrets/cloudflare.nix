{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets.cloudflare-api-key = {
      sopsFile = config.secrets.cloudflare.letsencrypt-token;
      mode = "0400";
      key = "data";
    };
  };
}
