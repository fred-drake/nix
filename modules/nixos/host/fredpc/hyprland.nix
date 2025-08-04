{
  pkgs,
  inputs,
  ...
}: {
  programs.hyprland = {
    enable = false;
    # xwayland.enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  };
}
