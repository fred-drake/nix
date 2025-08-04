{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  networking.networkmanager.enable = true;

  # services.greetd = {
  #   enable = false;
  #   # settings = {
  #   #   default_session = {
  #   #     command = "Hyprland";
  #   #     user = "fdrake";
  #   #   };
  #   # };
  # };

  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm = {
  #   enable = true;
  # };
  # services.xserver.desktopManager.plasma5.enable = true;
  # services.displayManager.sddm.wayland.enable = true;

  environment.systemPackages = with pkgs; [
    waybar
    wofi
  ];

  programs.waybar = {
    enable = true;
  };
}
