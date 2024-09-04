# Configuration specific to the Mac Studio machine
{ ... }: {
  homebrew = {
    casks = [ "mutedeck" "proxy-audio-device" ]; 
    masApps = {
      "iWallpaper - Live Wallpaper" = 1552826194;
    };
  };

  system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 2.0; # Set trackpad speed to a faster setting
}
