# Configuration specific to the MacBook Pro device.
_: {
  my.hasWoodpeckerAgent = true;
  my.hasIosSigning = true;

  homebrew = {
    brews = ["container" "steipete/tap/remindctl"];
    casks = ["bartender" "mutedeck" "naps2" "proxy-audio-device" "elgato-stream-deck" "elgato-camera-hub"];
    masApps = {
      "iWallpaper - Live Wallpaper" = 1552826194;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };
}
