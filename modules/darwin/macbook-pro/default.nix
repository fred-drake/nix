# Configuration specific to the MacBook Pro device.
{...}: let
  # Casks that are too large for the Mac Mini but fine here
  non-mac-mini-casks = ["godot" "steam" "wine-stable" "winbox"];
in {
  homebrew.casks = ["bartender" "vmware-fusion"] ++ non-mac-mini-casks;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };
}
