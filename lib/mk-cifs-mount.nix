# Helper to generate CIFS mount config for Hetzner Storage Box sub-accounts.
# Returns an attrset of sops.secrets, sops.templates, and fileSystems entries.
{
  config,
  pkgs,
}: {
  name,
  sub,
  secretsHost,
  mountPath ? "/mnt/${name}-storage",
  uid ? "1000",
  gid ? "1000",
  extraOptions ? [],
}: let
  storageBox = "u543742.your-storagebox.de";
in {
  sops.secrets = {
    "${name}-storage-username" = {
      sopsFile = config.secrets.host.${secretsHost}."${name}-storage";
      mode = "0400";
      key = "username";
    };
    "${name}-storage-password" = {
      sopsFile = config.secrets.host.${secretsHost}."${name}-storage";
      mode = "0400";
      key = "password";
    };
  };
  sops.templates."${name}-storage-credentials" = {
    content = ''
      username=${config.sops.placeholder."${name}-storage-username"}
      password=${config.sops.placeholder."${name}-storage-password"}
    '';
    mode = "0400";
  };
  environment.systemPackages = [pkgs.cifs-utils];
  fileSystems.${mountPath} = {
    device = "//${storageBox}/u543742-${sub}";
    fsType = "cifs";
    options =
      [
        "credentials=${config.sops.templates."${name}-storage-credentials".path}"
        "_netdev"
        "noauto"
        "x-systemd.automount"
        "uid=${uid}"
        "gid=${gid}"
        "iocharset=utf8"
      ]
      ++ extraOptions;
  };
}
