{
  config,
  pkgs,
  lib,
  ...
}: let
  storageBox = "u543742.your-storagebox.de";
  borgRepoBase = "/mnt/hetzner-backup/borg-repos";
  borgPassCommand = "cat ${config.sops.secrets.hetzner-borg-passphrase.path}";
  mount = "${pkgs.util-linux}/bin/mount";
  umount = "${pkgs.util-linux}/bin/umount";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Sub-accounts to back up with borg
  storages = {
    videos = "sub2";
    calibre = "sub5";
    gitea = "sub3";
    paperless = "sub4";
    nintendopower = "sub9";
    wowclient = "sub7";
  };

  # Backup groups by frequency
  dailyNames = ["gitea" "paperless"];
  weeklyNames = ["calibre"];
  monthlyNames = ["videos" "nintendopower" "wowclient"];

  allNames = dailyNames ++ weeklyNames ++ monthlyNames;

  # Mount a single CIFS share using a sops-rendered credentials file (with retry)
  mountOne = name: sub: ''
    for attempt in 1 2 3 4 5; do
      echo "Mount attempt $attempt for ${name}..."
      ${mount} -t cifs //${storageBox}/u543742-${sub} /mnt/backup-${name} \
        -o credentials=${config.sops.templates."${name}-storage-credentials".path},uid=0,gid=0,dir_mode=0755,file_mode=0644,iocharset=utf8 && break
      echo "Mount failed, waiting 30s before retry..."
      sleep 30
    done
    ${pkgs.util-linux}/bin/mountpoint -q /mnt/backup-${name} || { echo "ERROR: Failed to mount ${name} after 5 attempts"; exit 1; }
  '';

  unmountOne = name: ''
    ${umount} /mnt/backup-${name} 2>/dev/null || true
  '';

  # Custom paths per sub-account (default: entire mount)
  storagePaths = {
    videos = ["/mnt/backup-videos/library/home-videos"];
  };

  # Generate a borg backup job for a single sub-account
  mkBorgJob = name: sub: {
    repo = "${borgRepoBase}/${name}";
    paths = storagePaths.${name} or ["/mnt/backup-${name}"];

    encryption = {
      mode = "repokey-blake2";
      passCommand = borgPassCommand;
    };

    compression = "auto,zstd";
    startAt = []; # Driven by wrapper services
    doInit = true;
    privateTmp = false;
    failOnWarnings = false; # CIFS xattr warnings are benign

    readWritePaths = [
      "/tmp"
      "/mnt/backup-${name}"
      borgRepoBase
    ];

    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };

    preHook = mountOne name sub;
    postHook = unmountOne name;

    extraCreateArgs = ["--stats" "--checkpoint-interval" "600"];
  };

  # Generate a sequential wrapper script for a group of backups
  mkWrapperScript = groupName: names: let
    backupCommands =
      lib.imap0 (i: name: ''
        ${lib.optionalString (i > 0) ''
          echo "Waiting 30s before next backup..."
          sleep 30
        ''}
        echo "=== Starting ${groupName} backup: ${name} ==="
        ${systemctl} start --wait borgbackup-job-hetzner-${name}.service && \
          echo "=== Completed: ${name} ===" || \
          echo "=== WARNING: ${name} backup failed ==="
      '')
      names;
  in
    lib.concatStringsSep "\n" backupCommands;

  storageCredSecrets = lib.listToAttrs (lib.concatMap (name: [
      {
        name = "${name}-storage-username";
        value = {
          sopsFile = config.secrets.host.ironforge."${name}-storage";
          mode = "0400";
          key = "username";
        };
      }
      {
        name = "${name}-storage-password";
        value = {
          sopsFile = config.secrets.host.ironforge."${name}-storage";
          mode = "0400";
          key = "password";
        };
      }
    ])
    allNames);

  storageCredTemplates = lib.listToAttrs (map (name: {
      name = "${name}-storage-credentials";
      value = {
        content = ''
          username=${config.sops.placeholder."${name}-storage-username"}
          password=${config.sops.placeholder."${name}-storage-password"}
        '';
        mode = "0400";
      };
    })
    allNames);
in {
  environment.systemPackages = [pkgs.cifs-utils];

  sops.secrets =
    storageCredSecrets
    // {
      hetzner-borg-passphrase = {
        sopsFile = config.secrets.host.gnomeregan.borg-backup;
        mode = "0400";
        key = "passphrase";
      };
    };

  sops.templates = storageCredTemplates;

  systemd = {
    tmpfiles.rules =
      map (name: "d /mnt/backup-${name} 0755 root root -") allNames
      ++ ["d ${borgRepoBase} 0700 root root -"];

    services =
      {
        borg-backup-daily = {
          description = "Sequential borg backups (daily: gitea, paperless)";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          unitConfig.RequiresMountsFor = ["/mnt/hetzner-backup"];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "24h";
          };
          script = mkWrapperScript "daily" dailyNames;
        };

        borg-backup-weekly = {
          description = "Sequential borg backups (weekly: calibre)";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          unitConfig.RequiresMountsFor = ["/mnt/hetzner-backup"];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "24h";
          };
          script = mkWrapperScript "weekly" weeklyNames;
        };

        borg-backup-monthly = {
          description = "Sequential borg backups (monthly: videos, nintendopower, wowclient)";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          unitConfig.RequiresMountsFor = ["/mnt/hetzner-backup"];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "24h";
          };
          script = mkWrapperScript "monthly" monthlyNames;
        };
      }
      // lib.listToAttrs (map (name: {
          name = "borgbackup-job-hetzner-${name}";
          value.unitConfig.RequiresMountsFor = ["/mnt/hetzner-backup"];
        })
        allNames);

    timers = {
      borg-backup-daily = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "02:00";
          Persistent = true;
        };
      };

      borg-backup-weekly = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "Sun 02:00";
          Persistent = true;
        };
      };

      borg-backup-monthly = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-01 02:00";
          Persistent = true;
        };
      };
    };
  };

  services.borgbackup.jobs = lib.listToAttrs (map (name: {
      name = "hetzner-${name}";
      value = mkBorgJob name storages.${name};
    })
    allNames);
}
