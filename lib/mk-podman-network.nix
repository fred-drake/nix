# Helper to create a podman network systemd service.
# Returns a systemd.services attrset entry for the oneshot network creator.
{pkgs}: name: before: {
  "podman-network-${name}" = {
    description = "Create ${name} podman network with DNS enabled";
    wantedBy = ["multi-user.target"];
    inherit before;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create --ignore ${name}-net";
    };
  };
}
