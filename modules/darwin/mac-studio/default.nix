# Configuration specific to the Mac Studio machine
{
  non-mac-mini-casks,
  lib,
  ...
}: {
  # User configuration - override home directory for external drive
  users.users.fdrake.home = lib.mkForce "/Volumes/External/Users/fdrake";

  homebrew = {
    brews = ["container" "steipete/tap/remindctl"];
    casks = ["mutedeck" "proxy-audio-device" "elgato-stream-deck" "elgato-camera-hub" "vmware-fusion"] ++ non-mac-mini-casks;
    masApps = {
      "iWallpaper - Live Wallpaper" = 1552826194;
    };
  };

  system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 2.0; # Set trackpad speed to a faster setting

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      # The "Globe" MacOS ZMK key on the Kinesis Advantage keyboard does not appear to work, and we don't use
      # F13 anyway, so remap it to Fn and use F13 as the home row key.  Now we can take advantage
      # of window positioning shortcuts introduced in MacOS Sequoia.
      {
        HIDKeyboardModifierMappingSrc = 30064771176;
        HIDKeyboardModifierMappingDst = 1095216660483;
      }
    ];
  };
}
