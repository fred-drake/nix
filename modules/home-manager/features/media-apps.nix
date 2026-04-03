{
  pkgs,
  hostArgs,
  ...
}: {
  home.packages =
    (with pkgs; [
      ffmpeg
      imagemagick
      openai-whisper
      yt-dlp
      localsend
      wiki-tui
    ])
    ++ (
      if
        hostArgs.hostName
        == "fredpc"
        || hostArgs.hostName == "macbook-pro"
        || hostArgs.hostName == "mac-studio"
      then
        with pkgs; [
          discord
          slack
          spotify
          inkscape
          podman
          podman-tui
        ]
      else []
    );
}
