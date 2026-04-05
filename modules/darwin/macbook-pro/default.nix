# Configuration specific to the MacBook Pro device.
_: {
  homebrew.casks = ["bartender"];
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };
}
