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

  # internal.freddrake.com DNS is no longer pinned here. It is now served
  # tailnet-wide via headscale split DNS (internal.freddrake.com -> hearthstone),
  # so there is a single source of truth in the brainrush headscale config.
}
