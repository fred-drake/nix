# Home Manager feature: network tools (ssh, etc.)
_: {
  my.modules.home-manager.network-tools = {
    imports = [../home-manager/features/network-tools.nix];
  };
}
