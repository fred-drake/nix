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
      poppler-utils
      openai-whisper
      yt-dlp
      localsend
      wiki-tui
    ])
    ++ lib.optionals isWorkstation (with pkgs; [
      spotify
      inkscape
      podman
      podman-tui
    ]);
}
