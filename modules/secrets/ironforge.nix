{config, ...}: {
  sops = {
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      cloudflare-api-key = {
        sopsFile = config.secrets.cloudflare.letsencrypt-token;
        mode = "0400";
        key = "data";
      };
      videos-storage-username = {
        sopsFile = config.secrets.host.ironforge.videos-storage;
        mode = "0400";
        key = "username";
      };
      videos-storage-password = {
        sopsFile = config.secrets.host.ironforge.videos-storage;
        mode = "0400";
        key = "password";
      };
      downloads-storage-username = {
        sopsFile = config.secrets.host.ironforge.downloads-storage;
        mode = "0400";
        key = "username";
      };
      downloads-storage-password = {
        sopsFile = config.secrets.host.ironforge.downloads-storage;
        mode = "0400";
        key = "password";
      };
    };
    templates = {
      "videos-storage-credentials" = {
        content = ''
          username=${config.sops.placeholder."videos-storage-username"}
          password=${config.sops.placeholder."videos-storage-password"}
        '';
        mode = "0400";
      };
      "downloads-storage-credentials" = {
        content = ''
          username=${config.sops.placeholder."downloads-storage-username"}
          password=${config.sops.placeholder."downloads-storage-password"}
        '';
        mode = "0400";
      };
    };
  };
}
