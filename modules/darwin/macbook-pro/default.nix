# Configuration specific to the MacBook Pro device.
{ ... }: {
  homebrew.casks = [ "xp-pen" ];  # Install XP-Pen driver for digital drawing tablet
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;  # Remap Caps Lock to Control
  };
}
