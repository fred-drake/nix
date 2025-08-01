{
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};

  # Slow HDD spinning disks that are part of the array (not cache disks)
  slowDisks = {
    "/mnt/pool/ata-SAMSUNG_HD204UI_S2H7J1BZ930265-2TB" = {
      device = "/dev/disk/by-id/ata-SAMSUNG_HD204UI_S2H7J1BZ930265-part1";
      fsType = "xfs";
    };

    "/mnt/pool/ata-ST3000DM001-1CH166_W1F4BPQG-3TB" = {
      device = "/dev/disk/by-id/ata-ST3000DM001-1CH166_W1F4BPQG-part1";
      fsType = "xfs";
    };

    "/mnt/pool/ata-ST6000VN001-2BB186_ZCT2H3X9-6TB" = {
      device = "/dev/disk/by-id/ata-ST6000VN001-2BB186_ZCT2H3X9-part1";
      fsType = "xfs";
    };

    # "/mnt/pool/ata-WDC_WD120EDBZ-11B1HA0_5PKRDKNF-12TB" = {
    #   device = "/dev/disk/by-id/ata-WDC_WD120EDBZ-11B1HA0_5PKRDKNF-part1";
    #   fsType = "ext4";
    # };

    "/mnt/pool/ata-WDC_WD120EDGZ-11B1PA1_9LHZXKYG-12TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD120EDGZ-11B1PA1_9LHZXKYG-part1";
      fsType = "xfs";
    };

    # "/mnt/pool/ata-WDC_WD120EFBX-68B0EN0_5QKRMK5B-12TB" = {
    #   device = "/dev/disk/by-id/ata-WDC_WD120EFBX-68B0EN0_5QKRMK5B-part1";
    #   fsType = "ext4";
    # };

    # "/mnt/pool/ata-WDC_WD120EMFZ-11A6JA0_X1G1BDML-12TB" = {
    #   device = "/dev/disk/by-id/ata-WDC_WD120EMFZ-11A6JA0_X1G1BDML-part1";
    #   fsType = "xfs";
    # };
    "/mnt/pool/ata-WDC_WD142KFGX-68AFPN0_6AGD8A2S-14TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD142KFGX-68AFPN0_6AGD8A2S-part1";
      fsType = "xfs";
    };
    "/mnt/pool/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4JD389K-3TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N4JD389K-part1";
      fsType = "xfs";
    };
    "/mnt/pool/ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N2062630-3TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N2062630-part1";
      fsType = "xfs";
    };
    "/mnt/pool/ata-WDC_WD60EFAX-68SHWN0_WD-WX12D10PKKRP-6TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD60EFAX-68SHWN0_WD-WX12D10PKKRP-part1";
      fsType = "xfs";
    };
  };

  # Disk paths
  cachePath = "/mnt/cache/ata-CT1000MX500SSD1_2336E87351AC-1TB";
  storagePath = "/mnt/array/storage1";
  coldStoragePath = "/mnt/array/slowstorage1";

  # Fast SSD cache disks
  cacheDisks = {
    "${cachePath}" = {
      device = "/dev/disk/by-id/ata-CT1000MX500SSD1_2336E87351AC-part1";
      fsType = "xfs";
    };
  };

  # Parity disks
  parityDisks = {
    "/mnt/pool/ata-WDC_WD142KFGX-68AFPN0_6AGDDN7S-14TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD142KFGX-68AFPN0_6AGDDN7S-part1";
      fsType = "xfs";
    };
    "/mnt/pool/ata-WDC_WD140EDGZ-11B1PA0_9MJ2PD2U-14TB" = {
      device = "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_9MJ2PD2U-part1";
      fsType = "xfs";
    };
  };

  # Builds a colon separated list of disks for the mergerfs configuration
  slowPoolDisks = builtins.concatStringsSep ":" (builtins.attrNames slowDisks);
  fullPoolDisks = builtins.concatStringsSep ":" ((builtins.attrNames cacheDisks) ++ (builtins.attrNames slowDisks));

  # Builds a list of data disks for the snapraid configuration
  # Example: { "d1" = "/mnt/pool/ata-SAM...265-2TB"; "d2" = "/mnt/pool/ata-ST3...PQG-3TB"; }
  snapraidDataDisks = builtins.listToAttrs (
    lib.imap1 (i: key: {
      name = "d${toString (i + 1)}";
      value = key;
    }) (builtins.attrNames slowDisks)
  );

  # Builds a list of parity and content files for the snapraid configuration.
  # Each slow disk gets a content file and each parity disk gets a parity file.
  # Example: [ "/mnt/pool/ata-WDC_WD14...N7S-14TB/snapraid.parity" "/mnt/pool/ata-WDC_WD140...D2U-14TB/snapraid.parity" ]
  snapraidParityFiles = map (key: "${key}/snapraid.parity") (builtins.attrNames parityDisks);
  snapraidContentFiles = map (key: "${key}/snapraid.content") (builtins.attrNames slowDisks);
in {
  config = {
    fileSystems =
      slowDisks
      // cacheDisks
      // parityDisks
      // {
        "${storagePath}" = {
          device = fullPoolDisks;
          fsType = "mergerfs";
          options = ["minfreespace=20G" "cache.files=off" "category.create=ff" "func.getattr=newest" "dropcacheonclose=false"];
        };
        "${coldStoragePath}" = {
          device = slowPoolDisks;
          fsType = "mergerfs";
          options = ["minfreespace=20G" "cache.files=off" "category.create=pfrd" "func.getattr=newest" "dropcacheonclose=false"];
        };
      };

    services.snapraid = {
      enable = true;
      dataDisks = snapraidDataDisks;
      parityFiles = snapraidParityFiles;
      contentFiles = snapraidContentFiles;
      exclude = [];
      extraConfig = ''
        autosave 100
      '';
    };

    # MergerFS Cache Mover
    virtualisation.oci-containers = {
      containers = {
        mergerfs-cache-mover = {
          image = containers-sha."ghcr.io"."monstermuffin/mergerfs-cache-mover"."latest"."linux/amd64";
          autoStart = true;
          volumes = [
            "${cachePath}:/mnt/cache"
            "${coldStoragePath}:/mnt/cold"
            "/mnt/pool:/mnt/data-disks"
          ];
          environment = {
            CACHE_PATH = "/mnt/cache";
            BACKING_PATH = "/mnt/cold";
            EXCLUDED_DIRS = "sabnzbd_downloads,sabnzbd_downloads_incomplete";
            SCHEDULE = "0 3 * * *"; # Run at 3 AM daily
            THRESHOLD_PERCENTAGE = "5";
            TARGET_PERCENTAGE = "2";
            LOG_LEVEL = "INFO";
            MAX_WORKERS = "8";
            TZ = "America/New_York";
          };
          extraOptions = ["--cap-add=SYS_ADMIN" "--cap-add=DAC_READ_SEARCH"];
        };
      };
    };
  };
}
