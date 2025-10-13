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

  # Simple scan script (PDF, 600 DPI, Color, A4)
  scanScript = pkgs.writeShellScriptBin "scan" ''
    #!/usr/bin/env bash
    SCAN_DIR="/home/default/scans"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    SCAN_FILE="$SCAN_DIR/scan-$TIMESTAMP.pdf"

    echo "Starting scan (600 DPI, PDF)..."
    ${pkgs.sane-backends}/bin/scanimage \
      --device "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
      --format=pdf \
      --resolution=600 \
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

  # Duplex scan script (both sides, PDF, 600 DPI, Color, A4)
  scanDuplexScript = pkgs.writeShellScriptBin "scan-duplex" ''
    #!/usr/bin/env bash
    SCAN_DIR="/home/default/scans"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    SCAN_FILE="$SCAN_DIR/scan-duplex-$TIMESTAMP.pdf"

    echo "Starting duplex scan (600 DPI, PDF, both sides)..."
    ${pkgs.sane-backends}/bin/scanimage \
      --device "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
      --format=pdf \
      --resolution=600 \
      --mode=Color \
      --scan-area=A4 \
      --source="ADF Front" \
      --duplex=yes \
      --batch="$SCAN_DIR/page-%04d.pdf" \
      --batch-start=1

    # Merge all pages into single PDF if multiple files created
    if ls "$SCAN_DIR"/page-*.pdf 1> /dev/null 2>&1; then
      echo "Merging pages..."
      ${pkgs.poppler_utils}/bin/pdfunite "$SCAN_DIR"/page-*.pdf "$SCAN_FILE" 2>/dev/null

      if [ -f "$SCAN_FILE" ] && [ -s "$SCAN_FILE" ]; then
        rm -f "$SCAN_DIR"/page-*.pdf
        echo "✓ Duplex scan completed: $SCAN_FILE"
        ls -lh "$SCAN_FILE"
      else
        echo "✗ Failed to merge PDF pages"
        exit 1
      fi
    else
      echo "✗ No pages scanned"
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
    pkgs.poppler_utils # for pdfunite (merging PDFs)
    scanScript
    scanDuplexScript
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
