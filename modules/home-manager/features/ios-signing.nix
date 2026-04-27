{
  config,
  lib,
  osConfig ? {},
  ...
}: let
  hasIosSigning = (osConfig.my or {}).hasIosSigning or config.my.hasIosSigning;
  home = config.home.homeDirectory;
  provisioningProfilesDir = "${home}/Library/Developer/Xcode/UserData/Provisioning Profiles";
in
  lib.mkIf hasIosSigning {
    sops.secrets = {
      apple-distribution-p12 = {
        sopsFile = config.secrets.workstation.apple-distribution;
        mode = "0400";
        key = "data";
      };

      apple-distribution-p12-passphrase = {
        sopsFile = config.secrets.workstation.apple-app-store;
        mode = "0400";
        key = "apple-distribution-p12-passphrase";
      };

      thrifter-app-store-mobileprovision = {
        sopsFile = config.secrets.workstation.thrifter-app-store-mobileprovision;
        mode = "0400";
        key = "data";
        path = "${provisioningProfilesDir}/thrifter-app-store.mobileprovision";
      };
    };

    home.activation.ensureXcodeProvisioningDir = lib.hm.dag.entryBefore ["sops-nix"] ''
      run mkdir -p ${lib.escapeShellArg provisioningProfilesDir}
    '';
  }
