# Home Manager feature: SOPS secrets management
_: {
  my.modules.home-manager.secrets = {
    imports = [../home-manager/features/secrets.nix];
  };
}
