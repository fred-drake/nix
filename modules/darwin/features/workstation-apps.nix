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
      # Mirror the taps managed by nix-homebrew (lib/darwin-infra.nix) so they
      # appear as `tap` lines in the generated Brewfile. Without this, `brew
      # bundle` with cleanup = "zap" tries to untap every tapped repo (the
      # Brewfile lists none), erroring on core taps it can't remove and on
      # nix-homebrew's read-only tap dirs.
      taps = [
        "homebrew/core"
        "homebrew/cask"
        "homebrew/bundle"
        "nikitabobko/tap"
        "sst/tap"
        "steipete/tap"
        "facebook/fb"
      ];
    };
  }

  # Workstation apps — only hosts with isWorkstation = true
  (lib.mkIf config.my.isWorkstation {
    homebrew = {
      masApps = {
        "RunCat" = 1429033973;
        "The Unarchiver" = 425424353;
        "Xcode" = 497799835;
      };
      casks = [
        "nikitabobko/tap/aerospace"
        "balenaetcher"
        "bitwarden"
        "blackhole-2ch"
        "bruno"
        "claude"
        "cmux"
        "codex"
        "cursor"
        "daisydisk"
        "discord"
        "element"
        "finicky"
        "ghostty"
        "godot"
        "google-chrome"
        "google-drive"
        "gstreamer-runtime"
        "inkscape"
        "krita"
        "macdown"
        "maestral"
        "miniconda"
        "mouseless"
        "obs"
        "obsidian"
        "raycast"
        "slack"
        "sourcetree"
        "steam"
        "tailscale-app"
        "vlc"
        "whatsapp"
        "winbox"
        "wine-stable"
        "zen"
        "zoom"
      ];
      brews = [
        "sst/tap/opencode"
        "cmake"
        "ollama"
        "openssh"
        "ruby-install"
        "watch"
        "facebook/fb/idb-companion"
        "ios-deploy"
        "libimobiledevice"
      ];
      onActivation = {
        cleanup = "zap";
        autoUpdate = true;
        upgrade = true;
      };
    };
  })
]
