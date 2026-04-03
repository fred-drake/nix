{
  inputs,
  pkgs,
  ...
}: {
  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/desktop/input-sources".xkb-options = ["terminate:ctrl_alt_bksp" "ctrl:nocaps"];
      "org/gnome/shell/extensions/dash-to-dock".hot-keys = false;
      "org/gnome/shell/keybindings" = {
        "switch-to-application-1" = [""];
        "switch-to-application-2" = [""];
        "switch-to-application-3" = [""];
        "switch-to-application-4" = [""];
        "switch-to-application-5" = [""];
        "switch-to-application-6" = [""];
        "switch-to-application-7" = [""];
        "switch-to-application-8" = [""];
        "switch-to-application-9" = [""];
        "switch-to-application-10" = [""];
        "switch-to-application-11" = [""];
        "switch-to-application-12" = [""];
        "switch-to-application-13" = [""];
        "switch-to-application-14" = [""];
        "switch-to-application-15" = [""];
        "switch-to-application-16" = [""];
        "switch-to-application-17" = [""];
        "switch-to-application-18" = [""];
        "switch-to-application-19" = [""];
        "switch-to-application-20" = [""];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Toggle Albert";
        binding = "<Super>space";
        command = "albert toggle";
      };
    };
  };

  home.packages = with pkgs; [
    albert
    bitwarden-desktop
    brave
    gnome-tweaks
    zed-editor
    mako
  ];

  services.mako = {
    enable = true;
    settings = {
      defaultTimeout = 4000;
    };
  };

  programs.firefox = {
    enable = true;
    policies = {
      BlockAboutConfig = true;
      DefaultDownloadDirectory = "\${home}/Downloads";
    };

    profiles.default.extensions = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [bitwarden];
  };
}
