# Home Manager feature: SOPS secrets management
{...}: {
  my.modules.home-manager.secrets = {
    imports = [../home-manager/features/secrets.nix];
  };
}
