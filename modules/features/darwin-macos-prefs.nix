# Darwin feature: macOS system preferences
{...}: {
  my.modules.darwin.macos-prefs = {
    imports = [../darwin/features/macos-prefs.nix];
  };
}
