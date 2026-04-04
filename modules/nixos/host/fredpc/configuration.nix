{
  pkgs,
  pkgsCuda,
  pkgsUnstable,
  config,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  imports = [
    ../../../services/glance-dashboard.nix
    ../../../services/borg-backup.nix
  ];
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
      # xpadneo configured in modules/features/gaming.nix
    ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
    # xpadneo kernelModules configured in modules/features/gaming.nix
  };
  services = {
    displayManager.defaultSession = "hyprland";
    openssh.enable = true;
    # blueman configured in modules/features/gaming.nix
    # Pipewire is configured in modules/features/pipewire-audio.nix
    ratbagd.enable = true;
    ollama = {
      enable = false; # Running it from podman for now
      package = pkgsCuda.ollama-cuda;
      openFirewall = true;
      host = "0.0.0.0";
      port = 11434;
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0,1";
        OLLAMA_MODELS = "/storage1/models";
      };
    };
    mongodb = {
      enable = false;
    };
    # NVIDIA videoDrivers set in modules/features/nvidia-cuda.nix

    # Samba for sharing files with Windows VM
    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "fredpc";
          "security" = "user";
          "hosts allow" = "192.168.122. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        home = {
          path = "/home/fdrake";
          browseable = "yes";
          "read only" = "no";
          "valid users" = "fdrake";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    chromium
    curl
    bindfs
    file
    git
    zen-browser
    ghostty
    alsa-tools
    alsa-utils
    bitwarden-desktop
    hdparm
    usbutils
    kitty
    krita
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack

    # Gaming packages are in modules/features/gaming.nix
    libratbag
    piper

    # CUDA packages are in modules/features/nvidia-cuda.nix

    zed-editor
    docker-compose

    # Development
    alejandra

    obsidian
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

    extraHosts = ''
      192.168.30.58 local.brainrush.ai
      192.168.30.58 local-fredpc.brainrush.ai
      192.168.30.58 local-llm.brainrush.ai
      127.0.0.1     facebook.com www.facebook.com
    '';
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-users = ["root" "fdrake"];
      extra-substituters = [
        "https://cuda-maintainers.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };
  };

  programs = {
    zsh.enable = true;
    fish.enable = true;
    nix-ld.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    # rtkit configured in modules/features/pipewire-audio.nix
  };

  users.users = {
    fdrake = {
      isNormalUser = true;
      home = "/home/fdrake";
      description = "Fred Drake";
      extraGroups = ["wheel" "libvirtd" "kvm"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
      ];
      packages = with pkgs; [direnv git just];
      shell = pkgs.fish;
    };
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
  };

  hardware = {
    # Bluetooth configured in modules/features/gaming.nix
    # NVIDIA + graphics configured in modules/features/nvidia-cuda.nix
  };

  # Sound
  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # NIXOS_OZONE_WL is set in modules/features/hyprland-desktop.nix
  };

  # NVidia

  # Steam + GameMode configured in modules/features/gaming.nix

  # Podman
  virtualisation = {
    containers = {
      enable = true;
      # NVIDIA container runtime configured in modules/features/nvidia-cuda.nix
    };
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        ipmi = {
          image = containers-sha."docker.io"."solarkennedy/ipmi-kvm-docker"."latest"."linux/amd64";
          autoStart = true;
          ports = ["0.0.0.0:8080:8080"];
          environment = {
            RES = "1280x1024x24";
          };
        };
      };
    };
  };

  # OBS Studio with virtual camera
  security.polkit.enable = true;

  # nvidia-cdi-hook tmpfiles rule in modules/features/nvidia-cuda.nix

  system.stateVersion = "24.11";
}
