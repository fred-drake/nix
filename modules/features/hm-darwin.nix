# Home Manager feature: Darwin-specific settings (targets.darwin, finicky, etc.)
# The imported module guards itself with pkgs.stdenv.hostPlatform.isDarwin.
_: {
  my.modules.home-manager.darwin = {
    imports = [../home-manager/features/darwin-hm.nix];
  };
}
