{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  isWorkstation = (osConfig.my or {}).isWorkstation or config.my.isWorkstation;
in {
  home.packages =
    (with pkgs; [
      ffmpeg
      imagemagick
      openai-whisper
      yt-dlp
      localsend
      wiki-tui
    ])
    ++ lib.optionals isWorkstation (with pkgs; [
      discord
      slack
      spotify
      inkscape
      podman
      podman-tui
    ]);
}
