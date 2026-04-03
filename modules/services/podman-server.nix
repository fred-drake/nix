# Shared podman configuration for container-running servers.
# Used by ironforge and orgrimmar (and any future container hosts).
{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.podman-tui
  ];

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
