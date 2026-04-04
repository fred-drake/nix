# Darwin feature: Nix daemon configuration
{...}: {
  my.modules.darwin.nix-daemon = {
    imports = [../darwin/features/nix-daemon.nix];
  };
}
