# Home Manager feature: media applications (ffmpeg, spotify, discord, etc.)
{...}: {
  my.modules.home-manager.media-apps = {
    imports = [../home-manager/features/media-apps.nix];
  };
}
