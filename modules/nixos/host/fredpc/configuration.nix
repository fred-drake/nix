{
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  imports = [
    ./gnome.nix
    ./hyprland.nix
  ];
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
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
      acceleration = "cuda";
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
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack

    # Gaming
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
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
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
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  #   dedicatedServer.openFirewall = true;
  #   localNetworkGameTransfers.openFirewall = true;
  # };

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

  # Generate CDI specifications
  systemd.services.nvidia-cdi-generate = {
    description = "Generate NVIDIA CDI specifications";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml";
      RemainAfterExit = true;
    };
  };

  # Create symlink for nvidia-cdi-hook
  # This is a hack, but podman/crun insists on looking at this location for the CDI hook,
  # so at least this will persist with upgrades
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/nvidia-cdi-hook - - - - ${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-cdi-hook"
  ];

  system.stateVersion = "24.11";
}
