{
  pkgs,
  config,
  ...
}: let
  epsonscan2-custom = pkgs.epsonscan2.override {
    withNonFreePlugins = true;
    withGui = false;
  };
  scanimage-web = pkgs.callPackage ../../../../apps/scanimage-web.nix {};
in {
  # Allow unfree packages for scanner drivers
  nixpkgs.config.allowUnfree = true;

  # Scanner configuration
  environment.systemPackages = [
    epsonscan2-custom
    scanimage-web
    pkgs.usbutils # for lsusb debugging
    pkgs.poppler_utils # for pdfunite (merging PDFs)
    pkgs.inotify-tools
    pkgs.rsync
    pkgs.nodejs
  ];

  # Create the monitoring script
  environment.etc."auto-transfer.sh" = {
    text = ''
      #!${pkgs.bash}/bin/bash

      SOURCE_DIR="/home/default/scans"
      DEST_SERVER="default@${config.soft-secrets.host.paperless.admin_ip_address}"
      DEST_DIR="/var/paperless/consume"

      # Function to transfer a file
      transfer_file() {
          local filepath="$1"
          echo "$(date): Transferring: $filepath"

          ${pkgs.rsync}/bin/rsync -av -e "${pkgs.openssh}/bin/ssh" --remove-source-files "$filepath" "''${DEST_SERVER}:''${DEST_DIR}/"

          if [ $? -eq 0 ]; then
              echo "$(date): Successfully transferred: $filepath"
          else
              echo "$(date): Failed to transfer: $filepath" >&2
          fi
      }

      # Process any existing files in the source directory
      echo "$(date): Checking for existing files in $SOURCE_DIR"
      for file in "$SOURCE_DIR"/*; do
          if [ -f "$file" ]; then
              transfer_file "$file"
          fi
      done
      echo "$(date): Starting file monitoring"

      # Monitor for new files
      ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write -e moved_to "$SOURCE_DIR" --format '%w%f' |
      while read filepath; do
          echo "$(date): New file detected: $filepath"
          transfer_file "$filepath"
      done
    '';
    mode = "0755";
  };

  # Systemd services and tmpfiles
  systemd = {
    # Create the systemd service
    services.auto-transfer = {
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

    # Scanimage Web Application Service
    services.scanimage-web = {
      description = "Scanner Web Interface";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        OUTPUT_DIR = "/home/default/scans";
        IN_PROGRESS_DIR = "/home/default/scan-in-process";
        NODE_ENV = "production";
        HOST = "127.0.0.1";
        PORT = "3000";
        SCANIMAGE_PATH = "${pkgs.sane-backends}/bin/scanimage";
        # Use NixOS-managed SANE configuration which includes epsonscan2
        SANE_CONFIG_DIR = "/etc/sane-config";
        LD_LIBRARY_PATH = "/etc/sane-libs";
      };

      serviceConfig = {
        Type = "simple";
        User = "default";
        Group = "scanner";
        WorkingDirectory = "${scanimage-web}/lib/scanimage-web";
        ExecStart = "${scanimage-web}/bin/scanimage-web";
        Restart = "always";
        RestartSec = "10";
        StandardOutput = "journal";
        StandardError = "journal";
        # Ensure service has access to device files
        SupplementaryGroups = ["scanner"];
      };
    };

    # Create scans directory and SSH directory for secret
    tmpfiles.rules = [
      "d /home/default/scans 0755 default users -"
      "d /home/default/scan-in-process 0755 default users -"
      "d /home/default/.ssh 0700 default users -"
      "f /home/default/.ssh/id_ed25519.pub 0644 default users - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaQl0o8WD6inmcntGzrCmHdsB/Gj5PEUXSFM/eYrukI"
    ];
  };

  # Enable scanner support
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [epsonscan2-custom];

  # Add user to scanner group
  users.users.default.extraGroups = ["scanner"];

  # ACME configuration
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults = {
      inherit (config.soft-secrets.acme) email;
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
    certs."scanner.${config.soft-secrets.networking.domain}" = {
      domain = "scanner.${config.soft-secrets.networking.domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      s3Bucket = null;
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
  };

  # Nginx reverse proxy for scanimage-web
  services.nginx = {
    enable = true;
    virtualHosts."scanner.${config.soft-secrets.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_headers_hash_max_size 1024;
          proxy_headers_hash_bucket_size 128;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
}
