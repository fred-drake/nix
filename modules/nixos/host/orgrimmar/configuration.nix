_: {
  imports = [
    ../../../services/podman-server.nix
    ../../../services/nginx-acme-proxy.nix
  ];

  services.openssh = {
    ports = [2222];
    settings.ListenAddress = "0.0.0.0";
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
