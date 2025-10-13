{
  config,
  pkgs,
  lib,
  ...
}: let
  epsonscan2-custom = pkgs.epsonscan2.override {
    withNonFreePlugins = true;
    withGui = false;
  };

  # Script to execute when scanner button is pressed
  scanButtonScript = pkgs.writeShellScript "scan-button-action" ''
    #!/bin/sh
    # This script runs when the scanner button is pressed
    SCAN_DIR="/home/default/scans"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    SCAN_FILE="$SCAN_DIR/scan-$TIMESTAMP.png"

    # Create scan directory if it doesn't exist
    mkdir -p "$SCAN_DIR"

    # Perform the scan
    ${pkgs.sane-backends}/bin/scanimage \
      --device 'epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342' \
      --format=png \
      --resolution=200 \
      --mode=Color \
      --scan-area=A4 \
      > "$SCAN_FILE" 2>&1

    # Log the result
    if [ -f "$SCAN_FILE" ]; then
      echo "Scan completed: $SCAN_FILE" | systemd-cat -t scanbd -p info
    else
      echo "Scan failed" | systemd-cat -t scanbd -p err
    fi
  '';
in {
  # Allow unfree packages for scanner drivers
  nixpkgs.config.allowUnfree = true;

  # Scanner configuration
  environment.systemPackages = [
    epsonscan2-custom
    pkgs.usbutils # for lsusb debugging
    pkgs.scanbd
  ];

  # Enable scanner support
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [epsonscan2-custom];

  # Add user to scanner group
  users.users.default.extraGroups = ["scanner"];

  # Configure scanbd to detect button presses
  environment.etc."scanbd/scanbd.conf".text = ''
    global {
      debug   = true
      debug-level = 7
      user    = default
      group   = scanner

      saned   = "/run/current-system/sw/bin/saned"
      saned_opt  = {}
      saned_env  = { "SANE_CONFIG_DIR=/etc/sane-config" }

      scriptdir = /etc/scanbd/scripts

      pidfile = "/run/scanbd/scanbd.pid"

      timeout = 500

      environment {
        device = "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342"
      }
    }

    device epsonscan2 {
      filter = "^epsonscan2.*"
      desc   = "Epson ES-400"

      action scan {
        filter = "^scan.*"
        numerical-trigger {
          from-value = 0
          to-value   = 1
        }
        desc   = "Scan button pressed"
        script = "${scanButtonScript}"
      }
    }
  '';

  # Create scripts directory
  systemd.tmpfiles.rules = [
    "d /home/default/scans 0755 default users -"
  ];

  # Systemd service for scanbd
  systemd.services.scanbd = {
    description = "Scanner Button Daemon";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "forking";
      User = "default";
      Group = "scanner";
      RuntimeDirectory = "scanbd";
      PIDFile = "/run/scanbd/scanbd.pid";
      ExecStart = "${pkgs.scanbd}/bin/scanbd -c /etc/scanbd/scanbd.conf";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
