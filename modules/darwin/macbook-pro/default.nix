# Configuration specific to the MacBook Pro device.
{
  pkgs,
  non-mac-mini-casks,
  ...
}: {
  homebrew.casks = ["bartender" "vmware-fusion"] ++ non-mac-mini-casks;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };

  environment.systemPackages = with pkgs; [
    glance # Dashboard
  ];

  launchd.user.agents.glance = {
    serviceConfig = {
      ProgramArguments = [
        "/Users/fdrake/bin/glance"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
