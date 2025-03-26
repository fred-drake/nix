{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.cloudflare-api-key = {
    sopsFile = config.secrets.cloudflare.letsencrypt-token;
    mode = "0400";
    key = "data";
  };
}
