# This file contains common settings and configurations that apply to all
# macOS devices in the system. It includes:
#   - Environment setup (shells, packages, system paths)
#   - Font configurations
#   - Homebrew package management
#   - Nix configuration
#   - System programs and services
#   - Security settings
#
# Individual device-specific configurations should be placed in separate files.
{pkgs, ...}: {
  # Environment configuration
  environment = {
    etc = {
      "pam.d/sudo_local" = {
        text = ''
          auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
        '';
      };
    };
    shells = with pkgs; [
      bash
      zsh
      fish
      nushell
    ]; # Available shells
    systemPackages = [pkgs.coreutils]; # Core utilities package
    systemPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ]; # Add Homebrew paths
    pathsToLink = ["/Applications"]; # Link Applications directory
  };

  # Font configuration
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
  ];

  # Homebrew configuration
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true; # Disable quarantine for casks
    global.brewfile = true; # Use a global Brewfile
    masApps = {
      # Mac App Store applications
      "Bitwarden" = 1352778147;
      "Microsoft Remote Desktop" = 1295203466;
      # "OneDrive" = 823766827;
      "Pages" = 409201541;
      "RunCat" = 1429033973;
      "The Unarchiver" = 425424353;
      "Unsplash Wallpapers" = 1284863847;
      "UTM Virtual Machines" = 1538878817;
      "Xcode" = 497799835;
      "WireGuard" = 1451685025;
    };
    casks = [
      # Homebrew casks (GUI applications)
      # Using zed in homebrew because nix pkg is currently broken for Darwin
      "nikitabobko/tap/aerospace"
      "balenaetcher"
      "brave-browser"
      "bruno"
      "calibre"
      "daisydisk"
      "finicky"
      "ghostty"
      "google-drive"
      "krita"
      "macdown"
      "maestral"
      "mouseless"
      "obs"
      "obsidian"
      "raycast"
      "sourcetree"
      "vlc"
      "zen-browser"
    ];
    brews = [
      "openssh"
      "ruby-install"
      "watch"
      "pam-reattach"
    ]; # Homebrew formulae
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };

  # Nix configuration
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true; # Enable automatic garbage collection
      interval = [
        {
          Hour = 4;
          Minute = 30;
          Weekday = 2;
        }
      ]; # Garbage collect every Tuesday at 4:30 AM
      options = "--delete-older-than 7d"; # Delete old garbage
    };
    optimise.automatic = true; # Enable automatic garbage collection
    settings = {
      cores = 0; # Set Nix to use all available cores
      sandbox = false;
    };
  };
  # Program configurations
  programs = {
    direnv.enable = true; # Enable direnv for directory-specific environments
    zsh.enable = true; # Enable Zsh
  };

  # Security configuration
  security.pam.services.sudo_local.touchIdAuth = true; # Enable Touch ID for sudo

  # System configuration
  system = {
    # Activation script to install Rosetta 2 for x86 app compatibility
    activationScripts.extraActivation.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';
    # System defaults
    defaults = {
      dock.autohide = true; # Auto-hide the Dock
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
      trackpad.Clicking = true; # Enable tap to click
      menuExtraClock.ShowSeconds = true; # Show seconds in menu bar clock
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 14;
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        "com.apple.mouse.tapBehavior" = 1;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true; # Auto-install macOS updates
      WindowManager.StandardHideDesktopIcons = true; # Hide desktop icons
    };
    stateVersion = 4; # System state version
  };

  # User configuration
  users = {
    knownUsers = ["fdrake"]; # Known users
    users.fdrake = {
      uid = 501;
      home = "/Users/fdrake";
      shell = pkgs.zsh; # Set zsh as the user's shell
    };
  };
}
