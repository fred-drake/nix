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

  # CIFS options for backup mounts. Read-only, hardened against transient
  # session loss during long borg walks across the storage box:
  #   ro                 — backups only read
  #   vers=3.1.1         — required for resilienthandles
  #   resilienthandles   — kernel transparently reconnects open handles on
  #                        SMB session drop instead of failing reads with
  #                        EHOSTDOWN / EAGAIN partway through
  #   echo_interval=10   — faster keepalive so dead sessions are noticed
  #                        before borg has issued thousands of reads
  #   actimeo=300        — longer attr cache; backup tree doesn't change
  #                        under us so re-stat-ing is wasted round-trips
  cifsMountOpts = name:
    lib.concatStringsSep "," [
      "credentials=${config.sops.templates."${name}-storage-credentials".path}"
      "ro"
      "uid=0"
      "gid=0"
      "dir_mode=0755"
      "file_mode=0644"
      "iocharset=utf8"
      "vers=3.1.1"
      "resilienthandles"
      "echo_interval=10"
      "actimeo=300"
    ];

  # Mount a single CIFS share using a sops-rendered credentials file (with retry)
  mountOne = name: sub: ''
    for attempt in 1 2 3 4 5; do
      echo "Mount attempt $attempt for ${name}..."
      ${mount} -t cifs //${storageBox}/u543742-${sub} /mnt/backup-${name} \
        -o ${cifsMountOpts name} && break
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

  # Per-sub-account excludes. Borg uses fnmatch-style patterns.
  # gitea: the bleve issues indexer is a derived index whose backing bbolt
  # file (root.bolt) is held with an exclusive SMB open by the live gitea
  # container on orgrimmar, so a second CIFS client cannot read it
  # (STATUS_SHARING_VIOLATION → EACCES). It's rebuildable from the primary
  # DB via `gitea admin reindex`, so excluding it is safe.
  storageExcludes = {
    gitea = ["sh:**/indexers/**"];
  };

  # Generate a borg backup job for a single sub-account
  mkBorgJob = name: sub: {
    repo = "${borgRepoBase}/${name}";
    paths = storagePaths.${name} or ["/mnt/backup-${name}"];
    exclude = storageExcludes.${name} or [];

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
    lib.concatStringsSep "\n" backupCommands
    + ''

      echo "=== Refreshing backup status snapshot ==="
      ${systemctl} start --no-block backup-status.service
    '';

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

  # --- Backup freshness status (for the hermes agent) -----------------
  #
  # The borg repos live on a local disk but are root-only + passphrase
  # protected, so a non-root reader cannot query them directly. A root
  # timer (gen-backup-status) periodically reads the last archive time
  # from each repo and writes a world-readable JSON snapshot; the
  # `backup-status` report command (on every user's PATH, store-readable)
  # pretty-prints it. The hermes user runs `backup-status` over SSH.
  statusDir = "/var/lib/backup-status";
  statusFile = "${statusDir}/status.json";
  passphrasePath = config.sops.secrets.hetzner-borg-passphrase.path;

  # Max acceptable age per backup frequency before a volume is OVERDUE.
  thresholdSecs = {
    daily = 172800; # 2 days
    weekly = 691200; # 8 days
    monthly = 3024000; # 35 days
  };
  freqOf = name:
    if builtins.elem name dailyNames
    then "daily"
    else if builtins.elem name weeklyNames
    then "weekly"
    else "monthly";

  # name:repo entries consumed by both shell scripts.
  volEntries = lib.concatMapStringsSep " " (n: "${n}:${borgRepoBase}/${n}") allNames;
  # bash associative-array bodies keyed by volume name.
  freqDecl = lib.concatMapStringsSep " " (n: "[${n}]=${freqOf n}") allNames;
  thrDecl = lib.concatMapStringsSep " " (n: "[${n}]=${toString thresholdSecs.${freqOf n}}") allNames;

  genStatusScript = pkgs.writeShellApplication {
    name = "gen-backup-status";
    runtimeInputs = [pkgs.borgbackup pkgs.jq pkgs.coreutils];
    text = ''
      declare -a VOLUMES=( ${volEntries} )
      export BORG_PASSCOMMAND="cat ${passphrasePath}"

      errfile="$(mktemp)"
      trap 'rm -f "$errfile"' EXIT

      volumes_json='{}'
      for entry in "''${VOLUMES[@]}"; do
        name="''${entry%%:*}"
        repo="''${entry#*:}"
        if out=$(borg list "$repo" --last 1 --json 2>"$errfile"); then
          iso=$(printf '%s' "$out" | jq -r '.archives[0].time // empty')
          if [ -n "$iso" ]; then
            if epoch=$(date -d "$iso" +%s 2>/dev/null); then
              vol=$(jq -n --argjson e "$epoch" --arg i "$iso" \
                '{last_backup_epoch:$e, last_backup_iso:$i}')
            else
              vol=$(jq -n --arg i "$iso" \
                '{last_backup_epoch:null, last_backup_iso:$i, error:"unparseable time"}')
            fi
          else
            vol=$(jq -n '{last_backup_epoch:null, error:"no archives in repo"}')
          fi
        else
          err=$(tr '\n' ' ' < "$errfile" | head -c 200)
          vol=$(jq -n --arg e "$err" '{last_backup_epoch:null, error:$e}')
        fi
        volumes_json=$(printf '%s' "$volumes_json" \
          | jq --arg k "$name" --argjson v "$vol" '. + {($k): $v}')
      done

      now=$(date +%s)
      install -d -m 0755 "${statusDir}"
      printf '%s' "$volumes_json" \
        | jq --argjson now "$now" '{generated_epoch:$now, volumes:.}' \
        > "${statusFile}.tmp"
      mv "${statusFile}.tmp" "${statusFile}"
      chmod 0644 "${statusFile}"
    '';
  };

  reportScript = pkgs.writeShellApplication {
    name = "backup-status";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      STATUS_FILE="${statusFile}"
      declare -A FREQ=( ${freqDecl} )
      declare -A THRESH=( ${thrDecl} )

      if [ ! -r "$STATUS_FILE" ]; then
        echo "backup-status: no status file at $STATUS_FILE yet (refresh has not run)" >&2
        exit 1
      fi

      if [ "''${1:-}" = "--json" ]; then
        cat "$STATUS_FILE"
        exit 0
      fi

      now=$(date +%s)

      human() {
        local s=$1 d h m
        d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
        if [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
        elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
        else printf '%dm' "$m"; fi
      }

      printf '%-14s %-10s %-18s %-10s %s\n' VOLUME FREQUENCY LAST-BACKUP AGE STATUS
      while IFS=$'\t' read -r name epoch; do
        freq="''${FREQ[$name]:-?}"
        if [ "$epoch" = "null" ] || [ -z "$epoch" ]; then
          printf '%-14s %-10s %-18s %-10s %s\n' "$name" "$freq" "never" "-" "MISSING"
          continue
        fi
        age=$(( now - epoch ))
        when=$(date -d "@$epoch" '+%Y-%m-%d %H:%M')
        thr="''${THRESH[$name]:-0}"
        status=OK
        if [ "$thr" -gt 0 ] && [ "$age" -gt "$thr" ]; then status=OVERDUE; fi
        printf '%-14s %-10s %-18s %-10s %s\n' \
          "$name" "$freq" "$when" "$(human "$age")" "$status"
      done < <(jq -r '.volumes | to_entries[]
        | [.key, (.value.last_backup_epoch | tostring)] | @tsv' "$STATUS_FILE")

      generated=$(jq -r '.generated_epoch // empty' "$STATUS_FILE")
      if [ -n "$generated" ]; then
        g=$(( now - generated ))
        printf '\n(status snapshot generated %s ago)\n' "$(human "$g")"
      fi
    '';
  };
in {
  environment.systemPackages = [pkgs.cifs-utils reportScript];

  # Read-only agent account: SSHes in and runs `backup-status`. The
  # report command is on PATH and store-readable, so hermes can both
  # execute it and read its contents, as required.
  users.users.hermes = {
    isNormalUser = true;
    description = "Hermes agent — read-only backup status reporting";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF1HCnk7zYX1gijPLQS1kEdsqKTkD7WoB+2rCm/7lTJA"
    ];
  };

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

        # Refreshes the world-readable backup freshness snapshot that the
        # hermes user reads via `backup-status`.
        backup-status = {
          description = "Refresh borg backup freshness snapshot (${statusFile})";
          after = ["local-fs.target"];
          unitConfig.RequiresMountsFor = ["/mnt/hetzner-backup"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${genStatusScript}/bin/gen-backup-status";
            StateDirectory = "backup-status";
            StateDirectoryMode = "0755";
          };
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

      backup-status = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "1h";
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
