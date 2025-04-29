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
    pkgs.file
    pkgs.git
    inputs.zen-browser.packages."x86_64-linux".default
    pkgs.ghostty
    pkgs.alsa-tools
    pkgs.alsa-utils
    pkgs.bitwarden-desktop
    pkgs.usbutils

    # Gaming
    pkgs.steam
    pkgs.steamcmd
    pkgs.steam-tui
    pkgs.libratbag
    pkgs.piper

    # CUDA
    pkgs.cudaPackages.cudatoolkit
    pkgs.cudaPackages.cudnn

    pkgs.zed-editor
    pkgs.docker-compose
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
  nix.settings.trusted-users = ["root" "fdrake"];

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
  services.blueman.enable = true;

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;

  # Hyprland -- Disabled when using Gnome
  programs.hyprland = {
    enable = false;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  # NVidia
  hardware = {
    graphics.enable = true;
  };
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
  };

  services.ratbagd.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "cuda";
    openFirewall = true;
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "0,1";
      OLLAMA_MODELS = "/storage1/models";
    };
  };

  services.mongodb = {
    enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Podman
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  # Needed for Windsurf SSH
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    nodejs
  ];

  system.stateVersion = "24.11";
}
