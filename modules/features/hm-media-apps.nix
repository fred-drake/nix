# Home Manager feature: media applications (ffmpeg, spotify, discord, etc.)
_: {
  my.modules.home-manager.media-apps = {
    imports = [../home-manager/features/media-apps.nix];
  };
}
