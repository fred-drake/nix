{
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
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

    # Screensaver management scripts
    (writeShellScriptBin "disable-screensaver" ''
      #!/usr/bin/env bash
      
      # Script to disable GNOME screensaver
      
      echo "Disabling GNOME screensaver..."
      
      # Save current settings
      echo "Saving current settings..."
      CURRENT_IDLE_DELAY=$(${glib}/bin/gsettings get org.gnome.desktop.session idle-delay)
      CURRENT_LOCK_ENABLED=$(${glib}/bin/gsettings get org.gnome.desktop.screensaver lock-enabled)
      
      # Extract just the numeric value from "uint32 300" format
      IDLE_DELAY_NUM=$(echo "$CURRENT_IDLE_DELAY" | ${gnused}/bin/sed 's/uint32 //')
      LOCK_ENABLED_BOOL=$(echo "$CURRENT_LOCK_ENABLED" | ${gnused}/bin/sed 's/^true$/true/' | ${gnused}/bin/sed 's/^false$/false/')
      
      # If idle delay is 0, use a reasonable default (5 minutes = 300 seconds)
      if [ "$IDLE_DELAY_NUM" = "0" ]; then
          IDLE_DELAY_NUM="300"
          echo "Current idle delay is 0, will restore to 300 seconds (5 minutes)"
      fi
      
      # Store in a file for restoration
      cat > /tmp/screensaver-settings.txt << EOF
      IDLE_DELAY="$IDLE_DELAY_NUM"
      LOCK_ENABLED="$LOCK_ENABLED_BOOL"
      EOF
      
      echo "Saved settings to /tmp/screensaver-settings.txt"
      echo "  Idle delay: $CURRENT_IDLE_DELAY"
      echo "  Lock enabled: $CURRENT_LOCK_ENABLED"
      
      # Disable screensaver
      echo "Disabling screensaver..."
      ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay 0
      ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled false
      
      echo "Screensaver disabled!"
      echo "Run 'enable-screensaver' to restore settings"
    '')

    (writeShellScriptBin "enable-screensaver" ''
      #!/usr/bin/env bash
      
      # Script to restore GNOME screensaver settings
      
      echo "Restoring GNOME screensaver..."
      
      # Check if settings file exists
      if [ -f /tmp/screensaver-settings.txt ]; then
          echo "Found saved settings, restoring..."
          
          # Source the saved settings
          source /tmp/screensaver-settings.txt
          
          echo "Restoring settings:"
          echo "  Idle delay: $IDLE_DELAY seconds"
          echo "  Lock enabled: $LOCK_ENABLED"
          
          # Restore settings (no quotes needed for numeric values)
          ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay $IDLE_DELAY
          ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled $LOCK_ENABLED
          
          echo "Settings restored!"
          
          # Clean up the temporary file
          rm /tmp/screensaver-settings.txt
          echo "Cleaned up temporary settings file"
      else
          echo "No saved settings found, using defaults..."
          
          # Use reasonable defaults (5 minutes)
          ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay 300
          ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled true
          
          echo "Default settings applied (5 minute idle delay)"
      fi
      
      echo "Screensaver restored!"
    '')
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
      192.168.30.58 local-llm.brainrush.ai
    '';
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.settings.trusted-users = ["root" "fdrake"];

  programs.zsh.enable = true;
  programs.fish.enable = true;

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
    shell = pkgs.fish;
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

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
  hardware.nvidia-container-toolkit.enable = true;

  services.ratbagd.enable = true;

  services.ollama = {
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

  services.mongodb = {
    enable = true;
  };

  services.flatpak.enable = true; # Installing Steam through here

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  # Steam
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  #   dedicatedServer.openFirewall = true;
  #   localNetworkGameTransfers.openFirewall = true;
  # };

  # Podman
  virtualisation.containers.enable = true;
  virtualisation.containers = {
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
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  virtualisation.oci-containers = {
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
