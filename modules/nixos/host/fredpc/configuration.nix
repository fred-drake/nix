{
  inputs,
  pkgs,
  pkgsUnstable,
  config,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  imports = [
    ./gnome.nix
    ./hyprland.nix
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
      xpadneo
    ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
    kernelModules = ["xpadneo"];
  };
  services = {
    displayManager.defaultSession = "hyprland";
    openssh.enable = true;
    blueman.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    pulseaudio.enable = false;
    ratbagd.enable = true;
    ollama = {
      enable = false; # Running it from podman for now
      package = pkgs.ollama-cuda;
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
    xserver.videoDrivers = ["nvidia"];
  };

  environment.systemPackages = with pkgs; [
    chromium
    curl
    bindfs
    file
    git
    inputs.zen-browser.packages."x86_64-linux".default
    ghostty
    alsa-tools
    alsa-utils
    bitwarden-desktop
    usbutils
    kitty
    krita
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack

    # Gaming
    gamescope # Wayland micro-compositor for gaming performance
    protonup-qt # Manage GE-Proton and other custom Proton versions
    # steam
    # steamcmd
    # steam-tui
    libratbag
    piper

    # CUDA
    cudaPackages.cudatoolkit
    pkgsUnstable.cudaPackages.cudnn
    nvidia-container-toolkit
    crun

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
    settings.trusted-users = ["root" "fdrake"];
  };

  programs = {
    zsh.enable = true;
    fish.enable = true;
    nix-ld.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  users.users = {
    fdrake = {
      isNormalUser = true;
      home = "/home/fdrake";
      description = "Fred Drake";
      extraGroups = ["wheel"];
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
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Privacy = "device";
          JustWorksRepairing = "always";
          Class = "0x000100";
          FastConnectable = true;
        };
      };
    };
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
      powerManagement.enable = true;
    };
    nvidia-container-toolkit.enable = true;
  };

  # Sound
  # Hyprland -- Disabled when using Gnome
  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  # NVidia

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true; # Enable gamescope integration
  };

  # GameMode - CPU/GPU optimizations for gaming
  programs.gamemode.enable = true;

  # Podman
  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings = {
        engine = {
          runtimes = {
            nvidia = [
              "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime"
            ];
          };
        };
      };
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

  # Create symlink for nvidia-cdi-hook
  # This is a hack, but podman/crun insists on looking at this location for the CDI hook,
  # so at least this will persist with upgrades
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/nvidia-cdi-hook - - - - ${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-cdi-hook"
  ];

  system.stateVersion = "24.11";
}
