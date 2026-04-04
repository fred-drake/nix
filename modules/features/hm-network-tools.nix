# Home Manager feature: network tools (ssh, etc.)
{...}: {
  my.modules.home-manager.network-tools = {
    imports = [../home-manager/features/network-tools.nix];
  };
}
