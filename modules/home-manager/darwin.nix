{pkgs, ...}: {
  home.file = {
    ".finicky.js" = {source = ../../homefiles/finicky.js;};
  };
  home.packages = with pkgs; [
    mas # Mac App Store command-line interface
  ];

  # Set session variables
  home.sessionVariables = {
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
  };

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
