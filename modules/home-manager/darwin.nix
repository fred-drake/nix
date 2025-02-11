{pkgs, ...}: {
  home.packages = with pkgs; [
    bartender
    mas # Mac App Store command-line interface
    aerospace # MacOS tiling window manager
    skhd # Application hotkeys
  ];

  # macOS-specific settings
  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage =
    true;
  targets.darwin.defaults."com.apple.Safari".AutoFillCreditCardData = false;
  targets.darwin.defaults."com.apple.Safari".AutoFillPasswords = false;
  targets.darwin.defaults."com.apple.Safari".IncludeDevelopMenu = true;
  targets.darwin.defaults."com.apple.desktopservices".DSDontWriteNetworkStores =
    true;
  targets.darwin.defaults."com.apple.desktopservices".DSDontWriteUSBStores =
    true;
  targets.darwin.defaults."com.apple.finder".FXRemoveOldTrashItems = true;
  targets.darwin.defaults."com.microsoft.VSCode".ApplePressAndHoldEnabled = false;
  targets.darwin.search = "Google";
}
