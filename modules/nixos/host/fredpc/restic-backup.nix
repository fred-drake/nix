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

  # Script to create credentials and mount a single CIFS share (with retry)
  mountOne = name: sub: ''
    cat > /run/backup-creds/${name} <<CRED
    username=$(cat ${sopsBase}/${name}-storage-username)
    password=$(cat ${sopsBase}/${name}-storage-password)
    CRED
    chmod 0400 /run/backup-creds/${name}
    for attempt in 1 2 3 4 5; do
      echo "Mount attempt $attempt for ${name}..."
      ${mount} -t cifs //${storageBox}/u543742-${sub} /mnt/backup-${name} \
        -o credentials=/run/backup-creds/${name},uid=0,gid=0,dir_mode=0755,file_mode=0644,iocharset=utf8 && break
      echo "Mount failed, waiting 30s before retry..."
      sleep 30
    done
    ${pkgs.util-linux}/bin/mountpoint -q /mnt/backup-${name} || { echo "ERROR: Failed to mount ${name} after 5 attempts"; exit 1; }
  '';

  unmountOne = name: ''
    ${umount} /mnt/backup-${name} 2>/dev/null || true
    rm -f /run/backup-creds/${name}
  '';
in {
  environment.systemPackages = with pkgs; [
    cifs-utils
    restic
  ];

  # Create mount point and credential directory for home-videos
  systemd = {
    tmpfiles.rules = [
      "d /run/backup-creds 0700 root root -"
      "d /mnt/backup-videos 0755 root root -"
    ];

    services = {
      # Disable PrivateTmp so CIFS mounts in prepare scripts are visible to restic
      restic-backups-hetzner-home-videos.serviceConfig.PrivateTmp = lib.mkForce false;
    };
  };

  services.restic.backups = {
    # Home-videos backup at 1 AM
    hetzner-home-videos = {
      repository = resticRepo;
      passwordFile = resticPasswordFile;
      extraBackupArgs = ["--retry-lock=15m"];

      paths = [
        "/mnt/backup-videos/library/home-videos"
      ];

      backupPrepareCommand = ''
        mkdir -p /run/backup-creds
        ${mountOne "videos" "sub2"}
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
  };
}
