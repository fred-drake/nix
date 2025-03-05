# Configuration specific to the MacBook Pro device.
{non-mac-mini-casks, ...}: {
  homebrew.casks = ["xp-pen" "vmware-fusion"] ++ non-mac-mini-casks;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };
}
