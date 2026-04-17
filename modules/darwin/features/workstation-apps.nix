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
      user = config.my.username;
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
        "cursor"
        "daisydisk"
        "finicky"
        "ghostty"
        "godot"
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
        "steam"
        "vlc"
        "vmware-fusion"
        "whatsapp"
        "winbox"
        "wine-stable"
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
        "terminal-notifier"
        "facebook/fb/idb-companion"
        "ios-deploy"
      ];
      onActivation = {
        cleanup = "zap";
        autoUpdate = true;
        upgrade = true;
      };
    };
  })
]
