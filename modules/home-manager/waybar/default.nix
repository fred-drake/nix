{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file.".config/waybar/config".text = builtins.toJSON {
    position = "top";
    modules-center = ["clock"];

    clock = {
      format = "{:%d - %H:%M:%S}";
    };
  };

  home.file.".config/waybar/style.css".source = ./style.css;
}
