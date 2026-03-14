{
  pkgs,
  lib,
  ...
}: let
  storageBox = "u543742.your-storagebox.de";
  borgRepoBase = "/mnt/hetzner-backup/borg-repos";
  sopsBase = "/home/fdrake/.config/sops-nix/secrets";
  borgPassCommand = "cat ${sopsBase}/hetzner-borg-passphrase";
  mount = "${pkgs.util-linux}/bin/mount";
  umount = "${pkgs.util-linux}/bin/umount";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Sub-accounts to back up with borg
  storages = {
    calibre = "sub5";
    gitea = "sub3";
    paperless = "sub4";
    nintendopower = "sub9";
    wowclient = "sub7";
  };

  # Explicit execution order (most important first)
  storageNames = ["calibre" "gitea" "paperless" "nintendopower" "wowclient"];

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

  # Generate a borg backup job for a single sub-account
  mkBorgJob = name: sub: {
    repo = "${borgRepoBase}/${name}";
    paths = ["/mnt/backup-${name}"];

    encryption = {
      mode = "repokey-blake2";
      passCommand = borgPassCommand;
    };

    compression = "auto,zstd";
    startAt = []; # Driven by wrapper service
    doInit = true;
    privateTmp = false;
    failOnWarnings = false; # CIFS xattr warnings are benign

    readWritePaths = [
      "/tmp"
      "/run/backup-creds"
      "/mnt/backup-${name}"
      borgRepoBase
    ];

    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };

    preHook = ''
      mkdir -p /run/backup-creds
      ${mountOne name sub}
    '';

    postHook = unmountOne name;

    extraCreateArgs = ["--stats" "--checkpoint-interval" "600"];
  };
in {
  # Create mount points and credential directory
  systemd = {
    tmpfiles.rules =
      ["d /run/backup-creds 0700 root root -"]
      ++ map (name: "d /mnt/backup-${name} 0755 root root -") storageNames
      ++ ["d ${borgRepoBase} 0700 root root -"];

    # Wrapper service that runs each borg backup sequentially
    services.borg-backup-all-storage = {
      description = "Sequential borg backups for all storage sub-accounts";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "24h";
      };
      script = let
        backupCommands =
          lib.imap0 (i: name: ''
            ${lib.optionalString (i > 0) ''
              echo "Waiting 30s before next backup..."
              sleep 30
            ''}
            echo "=== Starting backup: ${name} ==="
            ${systemctl} start --wait borgbackup-job-hetzner-${name}.service && \
              echo "=== Completed: ${name} ===" || \
              echo "=== WARNING: ${name} backup failed ==="
          '')
          storageNames;
      in
        lib.concatStringsSep "\n" backupCommands;
    };

    # Wrapper timer triggers sequential backups at 2 AM
    timers.borg-backup-all-storage = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
    };
  };

  services.borgbackup.jobs = lib.listToAttrs (map (name: {
      name = "hetzner-${name}";
      value = mkBorgJob name storages.${name};
    })
    storageNames);
}
