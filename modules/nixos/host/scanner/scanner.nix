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

  # Simple scan script
  scanScript = pkgs.writeShellScriptBin "scan" ''
    #!/usr/bin/env bash
    SCAN_DIR="/home/default/scans"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    SCAN_FILE="$SCAN_DIR/scan-$TIMESTAMP.png"

    echo "Starting scan..."
    ${pkgs.sane-backends}/bin/scanimage \
      --device "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
      --format=png \
      --resolution=200 \
      --mode=Color \
      --scan-area=A4 \
      > "$SCAN_FILE"

    if [ -f "$SCAN_FILE" ] && [ -s "$SCAN_FILE" ]; then
      echo "✓ Scan completed: $SCAN_FILE"
      ls -lh "$SCAN_FILE"
    else
      echo "✗ Scan failed or produced empty file"
      rm -f "$SCAN_FILE"
      exit 1
    fi
  '';
in {
  # Allow unfree packages for scanner drivers
  nixpkgs.config.allowUnfree = true;

  # Scanner configuration
  environment.systemPackages = [
    epsonscan2-custom
    pkgs.usbutils # for lsusb debugging
    scanScript
  ];

  # Enable scanner support
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [epsonscan2-custom];

  # Add user to scanner group
  users.users.default.extraGroups = ["scanner"];

  # Create scans directory
  systemd.tmpfiles.rules = [
    "d /home/default/scans 0755 default users -"
  ];
}
