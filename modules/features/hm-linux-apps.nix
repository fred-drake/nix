# Home Manager feature: Linux-specific GUI applications (GNOME, Firefox, etc.)
# The imported module guards itself with pkgs.stdenv.hostPlatform.isLinux.
{...}: {
  my.modules.home-manager.linux-apps = {
    imports = [../home-manager/features/linux-apps.nix];
  };
}
