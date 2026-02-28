{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    sshfs
    restic
  ];

  # Allow FUSE mounts to be accessed by other users (needed for sshfs + restic)
  programs.fuse.userAllowOther = true;

  # Create sshfs mount point
  systemd.tmpfiles.rules = [
    "d /mnt/hetzner-sftp 0755 root root -"
  ];

  # sshfs mount unit that keeps the FUSE mount alive
  systemd.services.hetzner-sftp-mount = {
    description = "SSHFS mount for Hetzner Storage Box";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "forking";
      ExecStartPre = "-${pkgs.fuse}/bin/fusermount -u /mnt/hetzner-sftp";
      ExecStart = ''
        ${pkgs.sshfs}/bin/sshfs \
          -o Port=23,IdentityFile=/home/fdrake/.ssh/id_ed25519,StrictHostKeyChecking=no,allow_other,ServerAliveInterval=15,ServerAliveCountMax=3,reconnect \
          u543742@u543742.your-storagebox.de:. /mnt/hetzner-sftp
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/hetzner-sftp";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  services.restic.backups.hetzner-storage = {
    repository = "/mnt/hetzner-backup/restic-repo";
    passwordFile = "/home/fdrake/.config/sops-nix/secrets/hetzner-restic-password";

    paths = [
      "/mnt/hetzner-sftp/calibre"
      "/mnt/hetzner-sftp/emulation"
      "/mnt/hetzner-sftp/gitea"
      "/mnt/hetzner-sftp/nintendopower"
      "/mnt/hetzner-sftp/paperless"
      "/mnt/hetzner-sftp/wowclient"
      "/mnt/hetzner-sftp/videos/library/home-videos"
    ];

    backupPrepareCommand = ''
      # Start the sshfs mount service
      ${pkgs.systemd}/bin/systemctl start hetzner-sftp-mount.service

      # Verify mount succeeded
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/hetzner-sftp; then
        echo "ERROR: sshfs mount failed"
        exit 1
      fi
    '';

    backupCleanupCommand = ''
      ${pkgs.systemd}/bin/systemctl stop hetzner-sftp-mount.service
    '';

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
}
