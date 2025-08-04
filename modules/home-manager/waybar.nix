{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.waybar = {
    # enable = true;
    settings = {
      mainBar = {
        position = "top";
        modules-center = ["clock"];

        clock = {
          format = "%d - %H:%M:%S";
        };
      };
    };
  };
}
