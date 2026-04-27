# Home Manager feature: iOS code signing identity + provisioning profile (Darwin)
_: {
  my.modules.home-manager.ios-signing = {
    imports = [../home-manager/features/ios-signing.nix];
  };
}
