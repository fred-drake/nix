{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
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
