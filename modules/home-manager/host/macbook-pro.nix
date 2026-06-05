# Configuration specific to the MacBook Pro device.
{pkgs, ...}: {
  home.packages = with pkgs; [
    tailscale
  ];
}
