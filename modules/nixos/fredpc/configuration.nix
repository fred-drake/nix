{
  inputs,
  modulesPath,
  lib,
  pkgs,
  ...
}: {
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    inputs.zen-browser.packages."x86_64-linux".default
    pkgs.ghostty
    pkgs.alsa-tools
    pkgs.alsa-utils
    pkgs.bitwarden-desktop

    pkgs.waybar
    (pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
    }))
    pkgs.dunst
    pkgs.libnotify
    pkgs.swww
    pkgs.rofi-wayland
  ];

  networking = {
    hostName = "fredpc";
    firewall.enable = false;

    interfaces = {
      enp5s0.useDHCP = true;
      admin.useDHCP = true;
    };

    vlans.admin = {
      id = 1;
      interface = "enp5s0";
    };
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.fdrake = {
    isNormalUser = true;
    home = "/home/fdrake";
    description = "Fred Drake";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
    packages = with pkgs; [direnv git just];
    shell = pkgs.zsh;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    #   desktopManager.gnome.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # programs.dconf.enable = true;
  # programs.dconf.profiles = {
  #   uesr.databases = [
  #     {
  #       settings = with lib.gvariant; {
  #         "org/gnome/desktop/wm/preferences" = {
  #           workspace-only-on-primary = true;
  #         };
  #         "org/gnome/mutter" = {
  #           edge-tiling = true;
  #         };
  #         "org/gnome/shell" = {
  #           keyboard-shortcuts = ["<Super>q" "close-window"];
  #         };
  #         "org/gnome/settings-daemon/plugins/power" = {
  #           sleep-inactive-ac-type = "nothing";
  #           power-button-action = "interactive";
  #         };
  #       };
  #     }
  #   ];
  # };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  system.stateVersion = "24.11";
}
