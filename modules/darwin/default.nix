{...}: {
  imports = [
    ./features/nix-daemon.nix
    ./features/fonts.nix
    ./features/user-fdrake.nix
    ./features/macos-prefs.nix
    ./features/macos-security.nix
    ./features/workstation-apps.nix
  ];
}
