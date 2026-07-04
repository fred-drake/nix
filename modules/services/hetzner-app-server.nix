# Shared configuration for Hetzner application servers with podman + nginx.
# Used by ironforge, orgrimmar, and stormwind.
#
# containerDiskUUID is optional: when set, /var/lib/containers is mounted from a
# dedicated disk.
{containerDiskUUID ? null}: {lib, ...}: {
  imports = [
    ./podman-server.nix
    ./nginx-acme-proxy.nix
  ];

  services.openssh = {
    ports = [2222];
    settings.ListenAddress = "0.0.0.0";
  };

  fileSystems = lib.optionalAttrs (containerDiskUUID != null) {
    "/var/lib/containers" = {
      device = "/dev/disk/by-uuid/${containerDiskUUID}";
      fsType = "ext4";
    };
  };

  networking.firewall.allowedTCPPorts = [2222];
}
