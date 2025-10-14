{
  pkgs,
  config,
  ...
}: let
  epsonscan2-custom = pkgs.epsonscan2.override {
    withNonFreePlugins = true;
    withGui = false;
  };
in {
  # Allow unfree packages for scanner drivers
  nixpkgs.config.allowUnfree = true;

  # Scanner configuration
  environment.systemPackages = [
    epsonscan2-custom
    pkgs.usbutils # for lsusb debugging
    pkgs.poppler_utils # for pdfunite (merging PDFs)
    pkgs.inotify-tools
    pkgs.rsync
  ];

  # Create the monitoring script
  environment.etc."auto-transfer.sh" = {
    text = ''
      #!${pkgs.bash}/bin/bash

      SOURCE_DIR="/home/default/scans"
      DEST_SERVER="default@${config.soft-secrets.host.paperless.admin_ip_address}"
      DEST_DIR="/var/paperless/consume"

      ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write -e moved_to "$SOURCE_DIR" --format '%w%f' |
      while read filepath; do
          echo "$(date): New file detected: $filepath"

          ${pkgs.rsync}/bin/rsync -av --remove-source-files "$filepath" "''${DEST_SERVER}:''${DEST_DIR}/"

          if [ $? -eq 0 ]; then
              echo "$(date): Successfully transferred: $filepath"
          else
              echo "$(date): Failed to transfer: $filepath" >&2
          fi
      done
    '';
    mode = "0755";
  };

  # Create the systemd service
  systemd.services.auto-transfer = {
    description = "Automatic Document Transfer Service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "default";
      ExecStart = "/etc/auto-transfer.sh";
      Restart = "always";
      RestartSec = "10";
    };
  };

  # Enable scanner support
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [epsonscan2-custom];

  # Add user to scanner group
  users.users.default.extraGroups = ["scanner"];

  # Create scans directory and SSH directory for secret
  systemd.tmpfiles.rules = [
    "d /home/default/scans 0755 default users -"
    "d /home/default/scan-in-process 0755 default users -"
    "d /home/default/.ssh 0700 default users -"
    "f /home/default/.ssh/id_ed25519.pub 0644 default users - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaQl0o8WD6inmcntGzrCmHdsB/Gj5PEUXSFM/eYrukI"
  ];
}
