{pkgs, ...}: {
  home = {
    file = {
      ".finicky.js" = {source = ../../homefiles/finicky.js;};
    };
    packages = with pkgs; [
      mas # Mac App Store command-line interface
    ];
    sessionVariables = {
      HOMEBREW_PREFIX = "/opt/homebrew";
      HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
      HOMEBREW_REPOSITORY = "/opt/homebrew";
    };
  };

  targets.darwin = {
    currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
    defaults = {
      "com.apple.Safari" = {
        AutoFillCreditCardData = false;
        AutoFillPasswords = false;
        IncludeDevelopMenu = true;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder".FXRemoveOldTrashItems = true;
      "com.microsoft.VSCode".ApplePressAndHoldEnabled = false;
    };
    search = "Google";
  };
}
