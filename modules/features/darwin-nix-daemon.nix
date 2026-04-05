# Darwin feature: Nix daemon configuration
_: {
  my.modules.darwin.nix-daemon = {
    imports = [../darwin/features/nix-daemon.nix];
  };
}
