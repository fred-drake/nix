# Darwin feature: macOS security settings
{...}: {
  my.modules.darwin.macos-security = {
    imports = [../darwin/features/macos-security.nix];
  };
}
