# Preferences and configuration for all MacOS devices
{ pkgs, ... }: {
  environment.loginShell = pkgs.zsh;
  environment.shells = with pkgs; [ bash zsh ];
  environment.systemPackages = [ pkgs.coreutils ];
  environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];
  environment.pathsToLink = [ "/Applications" ];
  fonts.packages = [ (pkgs.nerdfonts.override { fonts = [ "Hack" "Meslo" ]; }) ];
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = {
      "Bitwarden" = 1352778147;
      "Microsoft Remote Desktop" = 1295203466;
      "OneDrive" = 823766827;
      "Pages" = 409201541;
      "The Unarchiver" = 425424353;
      "Unsplash Wallpapers" = 1284863847;
      "UTM Virtual Machines" = 1538878817;
      "Xcode" = 497799835;
    };
    casks = [
      "brave-browser"
      "daisydisk"
      "finicky"
      "goland"
      "google-drive"
      "krita"
      "maestral"
      "obsidian"
      "pycharm"
      "raycast"
      "rider"
      "rustrover"
      "sourcetree"
      "steam"
      "ultimaker-cura"
      "vlc"
      "wine-stable"
    ];
    taps = [ ];
    brews = [ "watch" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  programs.direnv.enable = true;
  programs.zsh.enable = true;
  security.pam.enableSudoTouchIdAuth = true;
  services.nix-daemon.enable = true;
  system.defaults = {
    dock.autohide = true;
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXPreferredViewStyle = "Nlsv";
      _FXShowPosixPathInTitle = true;
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    trackpad.Clicking = true;
    menuExtraClock.ShowSeconds = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
    NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
    WindowManager.StandardHideDesktopIcons = true;
  };
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.stateVersion = 4;
  users.knownUsers = [ "fdrake" ];
  users.users.fdrake.uid = 501;
  users.users.fdrake.home = "/Users/fdrake";
  users.users.fdrake.shell = pkgs.zsh;
}

