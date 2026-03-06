{
  pkgs,
  lib,
  ...
}: let
  storageBox = "u543742.your-storagebox.de";
  resticRepo = "/mnt/hetzner-backup/restic-repo";
  resticPasswordFile = "/home/fdrake/.config/sops-nix/secrets/hetzner-restic-password";
  sopsBase = "/home/fdrake/.config/sops-nix/secrets";
  mount = "${pkgs.util-linux}/bin/mount";
  umount = "${pkgs.util-linux}/bin/umount";

  # Each storage sub-account to back up
  storages = {
    videos = "sub2";
    gitea = "sub3";
    paperless = "sub4";
    calibre = "sub5";
    wowclient = "sub7";
    emulation = "sub8";
    nintendopower = "sub9";
  };

  # Script to create credentials and mount a single CIFS share
  mountOne = name: sub: ''
    cat > /run/backup-creds/${name} <<CRED
    username=$(cat ${sopsBase}/${name}-storage-username)
    password=$(cat ${sopsBase}/${name}-storage-password)
    CRED
    chmod 0400 /run/backup-creds/${name}
    ${mount} -t cifs //${storageBox}/u543742-${sub} /mnt/backup-${name} \
      -o credentials=/run/backup-creds/${name},uid=0,gid=0,dir_mode=0755,file_mode=0644,iocharset=utf8
  '';

  unmountOne = name: ''
    ${umount} /mnt/backup-${name} 2>/dev/null || true
    rm -f /run/backup-creds/${name}
  '';

  # Mount/unmount scripts for the main backup (all except videos)
  mainStorages = lib.filterAttrs (n: _: n != "videos") storages;
  mountAllMain = lib.concatStringsSep "\n" (lib.mapAttrsToList mountOne mainStorages);
  unmountAllMain = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _: unmountOne name) mainStorages);
in {
  environment.systemPackages = with pkgs; [
    cifs-utils
    restic
  ];

  # Create mount points and credential directory
  systemd = {
    tmpfiles.rules =
      ["d /run/backup-creds 0700 root root -"]
      ++ lib.mapAttrsToList (name: _: "d /mnt/backup-${name} 0755 root root -") storages;

    services = {
      # Disable PrivateTmp so CIFS mounts in prepare scripts are visible to restic
      restic-backups-hetzner-home-videos.serviceConfig.PrivateTmp = lib.mkForce false;
      restic-backups-hetzner-storage = {
        serviceConfig.PrivateTmp = lib.mkForce false;
        # Ensure storage backup waits for home-videos to finish (avoid overloading storage box)
        after = ["restic-backups-hetzner-home-videos.service"];
      };
    };
  };

  services.restic.backups = {
    # Dedicated home-videos backup (runs first at 1 AM)
    hetzner-home-videos = {
      repository = resticRepo;
      passwordFile = resticPasswordFile;
      extraBackupArgs = ["--retry-lock=15m"];

      paths = [
        "/mnt/backup-videos/library/home-videos"
      ];

      backupPrepareCommand = ''
        mkdir -p /run/backup-creds
        ${mountOne "videos" storages.videos}
      '';

      backupCleanupCommand = unmountOne "videos";

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      timerConfig = {
        OnCalendar = "01:00";
        Persistent = true;
      };
    };

    # Main backup for everything else (runs at 2 AM)
    hetzner-storage = {
      repository = resticRepo;
      passwordFile = resticPasswordFile;
      extraBackupArgs = ["--retry-lock=15m"];

      paths = [
        "/mnt/backup-calibre"
        "/mnt/backup-emulation"
        "/mnt/backup-gitea"
        "/mnt/backup-nintendopower"
        "/mnt/backup-paperless"
        "/mnt/backup-wowclient"
      ];

      backupPrepareCommand = ''
        mkdir -p /run/backup-creds
        ${mountAllMain}
      '';

      backupCleanupCommand = unmountAllMain;

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
    };
  };
}
