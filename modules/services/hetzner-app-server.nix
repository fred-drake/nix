# Shared configuration for Hetzner application servers with podman + nginx.
# Used by ironforge and orgrimmar.
{containerDiskUUID}: {
  imports = [
    ./podman-server.nix
    ./nginx-acme-proxy.nix
  ];

  services.openssh = {
    ports = [2222];
    settings.ListenAddress = "0.0.0.0";
  };

  fileSystems."/var/lib/containers" = {
    device = "/dev/disk/by-uuid/${containerDiskUUID}";
    fsType = "ext4";
  };

  networking.firewall.allowedTCPPorts = [2222];
}
