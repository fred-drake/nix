# Darwin feature: fdrake user account configuration
{...}: {
  my.modules.darwin.user-fdrake = {
    imports = [../darwin/features/user-fdrake.nix];
  };
}
