# Helper to generate CIFS mount config for Hetzner Storage Box sub-accounts.
# Returns an attrset of sops.secrets, sops.templates, and fileSystems entries.
{
  config,
  pkgs,
}: {
  name,
  sub,
  secretsHost,
  mountPath ? "/mnt/${name}-storage",
  uid ? "1000",
  gid ? "1000",
  extraOptions ? [],
}: let
  storageBox = "u543742.your-storagebox.de";
  metricDir = "/var/lib/prometheus-node-exporter-text-files";
  healthCheck = pkgs.writeShellScript "storagebox-cifs-health-${name}" ''
    set -u

    metric="${metricDir}/storagebox-cifs-${name}.prom"
    tmp="$metric.tmp"
    probe="${mountPath}/.storagebox-healthcheck-${name}"
    healthy=0
    dns_match=0

    dns_ips="$(${pkgs.getent}/bin/getent ahostsv4 ${storageBox} 2>/dev/null \
      | ${pkgs.gawk}/bin/awk '$2 == "STREAM" { print $1 }' \
      | ${pkgs.coreutils}/bin/sort -u)"

    mounted_ip="$(${pkgs.util-linux}/bin/findmnt -n -t cifs -o FS-OPTIONS -T ${mountPath} 2>/dev/null \
      | ${pkgs.coreutils}/bin/tr ',' '\n' \
      | ${pkgs.gnused}/bin/sed -n 's/^addr=//p' \
      | ${pkgs.coreutils}/bin/head -n1)"

    # An inactive automount has no CIFS address yet. Trigger it with the same
    # bounded write probe used below, then inspect the resulting mount.
    if [ -z "$mounted_ip" ]; then
      ${pkgs.coreutils}/bin/timeout 15 ${pkgs.coreutils}/bin/touch "$probe" 2>/dev/null || true
      mounted_ip="$(${pkgs.util-linux}/bin/findmnt -n -t cifs -o FS-OPTIONS -T ${mountPath} 2>/dev/null \
        | ${pkgs.coreutils}/bin/tr ',' '\n' \
        | ${pkgs.gnused}/bin/sed -n 's/^addr=//p' \
        | ${pkgs.coreutils}/bin/head -n1)"
    fi

    if [ -n "$mounted_ip" ] && printf '%s\n' "$dns_ips" | ${pkgs.gnugrep}/bin/grep -Fqx "$mounted_ip"; then
      dns_match=1
      if ${pkgs.coreutils}/bin/timeout 15 ${pkgs.coreutils}/bin/touch "$probe" 2>/dev/null \
        && ${pkgs.coreutils}/bin/timeout 15 ${pkgs.coreutils}/bin/rm -f "$probe" 2>/dev/null; then
        healthy=1
      fi
    fi

    cat >"$tmp" <<EOF
    # HELP storagebox_cifs_mount_healthy Whether the CIFS mount passed DNS-address and read/write checks.
    # TYPE storagebox_cifs_mount_healthy gauge
    storagebox_cifs_mount_healthy{name="${name}"} $healthy
    # HELP storagebox_cifs_mount_dns_match Whether the mounted server address is present in current DNS.
    # TYPE storagebox_cifs_mount_dns_match gauge
    storagebox_cifs_mount_dns_match{name="${name}"} $dns_match
    EOF
    ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
    ${pkgs.coreutils}/bin/mv "$tmp" "$metric"
  '';
in {
  sops.secrets = {
    "${name}-storage-username" = {
      sopsFile = config.secrets.host.${secretsHost}."${name}-storage";
      mode = "0400";
      key = "username";
    };
    "${name}-storage-password" = {
      sopsFile = config.secrets.host.${secretsHost}."${name}-storage";
      mode = "0400";
      key = "password";
    };
  };
  sops.templates."${name}-storage-credentials" = {
    content = ''
      username=${config.sops.placeholder."${name}-storage-username"}
      password=${config.sops.placeholder."${name}-storage-password"}
    '';
    mode = "0400";
  };
  environment.systemPackages = [pkgs.cifs-utils];

  systemd.services."storagebox-cifs-health-${name}" = {
    description = "Check Hetzner Storage Box CIFS mount ${name}";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = healthCheck;
      TimeoutStartSec = "40s";
    };
  };
  systemd.timers."storagebox-cifs-health-${name}" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "1m";
      RandomizedDelaySec = "10s";
    };
  };

  fileSystems.${mountPath} = {
    device = "//${storageBox}/u543742-${sub}";
    fsType = "cifs";
    options =
      [
        "credentials=${config.sops.templates."${name}-storage-credentials".path}"
        "_netdev"
        "noauto"
        "x-systemd.automount"
        "uid=${uid}"
        "gid=${gid}"
        "iocharset=utf8"
        # Read-mostly media share: relax CIFS metadata caching so jellyfin
        # library walks don't round-trip a stat() per entry to the Storage Box.
        "cache=loose"
        "actimeo=60"
      ]
      ++ extraOptions;
  };
}
