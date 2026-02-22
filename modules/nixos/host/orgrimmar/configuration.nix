{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    podman-tui
  ];

  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults = {
      inherit (config.soft-secrets.acme) email;
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
  };

  services.openssh = {
    ports = [2222];
    settings.ListenAddress = "0.0.0.0";
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  fileSystems."/var/lib/containers" = {
    device = "/dev/disk/by-uuid/59f51d47-a712-4744-857d-662fd7553606";
    fsType = "ext4";
  };

  networking = {
    hostName = "orgrimmar";
    firewall.allowedTCPPorts = [2222];
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.4";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
