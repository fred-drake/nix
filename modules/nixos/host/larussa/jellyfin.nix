{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "jellyfin";
  proxyPort = "8096";
in {
  # NVidia - Headless configuration
  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      nvidiaPersistenced = false;
    };
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
    graphics.enable = true;
    nvidia-container-toolkit = {
      enable = true;
      # Ensure the container toolkit can access NVIDIA devices
      package = pkgs.nvidia-container-toolkit;
    };
  };
  # Load the NVIDIA drivers in the initrd
  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  # Load NVIDIA kernel modules without X server
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  # Make sure the NVIDIA kernel modules are loaded at boot
  boot.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  # Create NVIDIA device nodes at boot
  services.udev.extraRules = ''
    # Create /dev/nvidia-uvm when nvidia_uvm is loaded
    KERNEL=="nvidia_uvm", RUN+="${pkgs.coreutils}/bin/mkdir -p /dev/nvidia"
    KERNEL=="nvidia_uvm", RUN+="${pkgs.coreutils}/bin/mknod -m 666 /dev/nvidia-uvm c \$major 0"
    KERNEL=="nvidia_uvm", RUN+="${pkgs.coreutils}/bin/ln -sf /dev/nvidia-uvm /dev/nvidia/uvm"
    # Create nvidia device nodes
    KERNEL=="nvidia", RUN+="${pkgs.coreutils}/bin/mknod -m 666 /dev/nvidia0 c \$major 0"
    KERNEL=="nvidia", RUN+="${pkgs.coreutils}/bin/mknod -m 666 /dev/nvidiactl c \$major 255"
  '';
  # Disable X server but keep the NVIDIA driver configuration
  services.xserver = {
    enable = false;
    videoDrivers = ["nvidia"];
  };

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    # Add nvidia-container-toolkit to Podman packages
    extraPackages = [pkgs.nvidia-container-toolkit];
  };

  # The NVIDIA Container Toolkit is already enabled in the hardware.nvidia section

  systemd.tmpfiles.rules = [
    "d /var/jellyfin/config 0755 99 100 -"
    "d /var/jellyfin/cache 0755 99 100 -"
    "d /var/jellyfin/log 0755 99 100 -"
    "d /var/sabnzbd/config 0755 99 100 -"
    "d /var/sabnzbd/nzb_backup 0755 99 100 -"
    "d /var/sabnzbd/admin 0755 99 100 -"
    "d /var/sabnzbd/backup 0755 99 100 -"
    "d /var/sabnzbd/log 0755 99 100 -"
  ];

  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        inherit (config.soft-secrets.acme) email;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare-api-key.path;
      };
      certs = {
        "${host}.${config.soft-secrets.networking.domain}" = {
          domain = "${host}.${config.soft-secrets.networking.domain}";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          webroot = null;
          listenHTTP = null;
          s3Bucket = null;
          environmentFile = config.sops.secrets.cloudflare-api-key.path;
        };
        "sabnzbd.${config.soft-secrets.networking.domain}" = {
          domain = "sabnzbd.${config.soft-secrets.networking.domain}";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          webroot = null;
          listenHTTP = null;
          s3Bucket = null;
          environmentFile = config.sops.secrets.cloudflare-api-key.path;
        };
      };
    };
  };

  services = {
    nginx = {
      enable = true;
      virtualHosts = {
        "${host}.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${proxyPort}";
            proxyWebsockets = true;
            extraConfig = ''
              # Increase the maximum size of the hash table
              proxy_headers_hash_max_size 1024;

              # Increase the bucket size of the hash table
              proxy_headers_hash_bucket_size 128;

              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
        "sabnzbd.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            proxyWebsockets = true;
            extraConfig = ''
              # Increase the maximum size of the hash table
              proxy_headers_hash_max_size 1024;

              # Increase the bucket size of the hash table
              proxy_headers_hash_bucket_size 128;

              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      jellyfin = {
        image = containers-sha."docker.io"."jellyfin/jellyfin"."latest"."linux/amd64";
        autoStart = true;
        ports = ["127.0.0.1:8096:8096"];
        volumes = [
          "/var/jellyfin/config:/config"
          "/var/jellyfin/cache:/cache"
          "/var/jellyfin/log:/log"
          "/mnt/array/storage1/videos:/media"
        ];
        environment = {
          PUID = "99";
          PGID = "100";
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
          TZ = "America/New_York";
        };
        extraOptions = [
          "--gpus=all"
          "--security-opt=label=disable"
        ];
      };
      sabnzbd = {
        image = containers-sha."ghcr.io"."linuxserver/sabnzbd"."latest"."linux/amd64";
        autoStart = true;
        ports = ["127.0.0.1:8080:8080"];
        volumes = [
          "/var/sabnzbd/config:/config"
          "/var/sabnzbd/nzb_backup:/nzb_backup"
          "/var/sabnzbd/admin:/admin"
          "/var/sabnzbd/backup:/backup"
          "/var/sabnzbd/log:/log"
          "/mnt/array/storage1:/storage"
        ];
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/New_York";
        };
      };
    };
  };
}
