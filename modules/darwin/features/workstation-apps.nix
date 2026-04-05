{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  # Base programs and homebrew — all Darwin hosts
  {
    environment = {
      systemPackages = [
        pkgs.coreutils
      ];
      systemPath = [];
      pathsToLink = ["/Applications"];
    };

    programs = {
      direnv.enable = true;
      zsh.enable = true;
      fish.enable = true;
    };

    homebrew = {
      enable = true;
      user = "fdrake";
      caskArgs.no_quarantine = true;
      global.brewfile = true;
    };
  }

  # Workstation apps — only hosts with isWorkstation = true
  (lib.mkIf config.my.isWorkstation {
    homebrew = {
      masApps = {
        "RunCat" = 1429033973;
        "The Unarchiver" = 425424353;
        "WireGuard" = 1451685025;
        "Xcode" = 497799835;
      };
      casks = [
        "nikitabobko/tap/aerospace"
        "balenaetcher"
        "bitwarden"
        "bruno"
        "claude"
        "daisydisk"
        "finicky"
        "ghostty"
        "google-chrome"
        "google-drive"
        "inkscape"
        "krita"
        "macdown"
        "maestral"
        "mouseless"
        "obs"
        "obsidian"
        "raycast"
        "sourcetree"
        "vlc"
        "whatsapp"
        "zen"
        "zoom"
      ];
      brews = [
        "sst/tap/opencode"
        "cmake"
        "openssh"
        "ruby-install"
        "watch"
        "poppler"
      ];
      onActivation = {
        cleanup = "zap";
        autoUpdate = true;
        upgrade = true;
      };
    };
  })
]
