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
      # Images are pulled by digest, so each update leaves the superseded
      # digest behind with no tag and no container referencing it. Without GC
      # these orphans accumulate until /var/lib/containers fills (this filled
      # orgrimmar's 40G container disk to 100%). Weekly `prune --all` reaps any
      # image no container is using; running services are never touched.
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = ["--all"];
      };
    };
  };
}
