# Darwin feature: workstation applications (Homebrew casks, etc.)
_: {
  my.modules.darwin.workstation-apps = {
    imports = [../darwin/features/workstation-apps.nix];
  };
}
