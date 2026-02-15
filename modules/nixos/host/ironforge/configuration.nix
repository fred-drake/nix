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
    device = "/dev/disk/by-uuid/69caea45-e319-47d5-b088-b8155a301e12";
    fsType = "ext4";
  };

  networking = {
    hostName = "ironforge";
    firewall.allowedTCPPorts = [2222];
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.3";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
