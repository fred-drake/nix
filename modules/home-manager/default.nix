# Home Manager Configuration for macOS
#
# This file defines the Home Manager configuration for macOS systems.
# It includes:
#   - Package installations
#   - Program configurations (git, kitty, neovim, vscode, zsh, etc.)
#   - Environment variables and shell aliases
#   - macOS-specific settings and defaults
#
# The configuration uses the Nix package manager and various Nix-related tools
# to manage the user environment in a declarative and reproducible manner.

# Home Manager configuration for macOS
{ inputs, outputs, pkgs, nixpkgs, ... }:
let
in
{
  # Import additional configuration files
  imports = [
    ../../apps/kitty.nix
    ../../apps/zsh.nix
    ../../apps/fish.nix
  ];

  # Enable and configure EditorConfig
  editorconfig.enable = true;
  editorconfig.settings = {
    "*" = {
      charset = "utf-8";
      end_of_line = "lf";
      trim_trailing_whitespace = true;
      insert_final_newline = true;
      max_line_width = 100;
      indent_style = "space";
      indent_size = 4;
    };
    # Specific settings for certain file types
    "*.{toml,js,nix,yaml}" = {
      indent_size = 2;
    };
  };

home.file = {
  "bin" = {
    source = ../../homefiles/bin;
    recursive = true;
  };

  ".ssh" = {
    source = ../../homefiles/ssh;
    recursive = true;
  };

  ".config" = {
    source = ../../homefiles/config;
    recursive = true;
  };

  "Pictures" = {
    source = ../../homefiles/Pictures;
    recursive = true;
  };

  ".finicky.js" = {
    source = ../../homefiles/finicky.js;
  };

  ".hgignore_global" = {
    source = ../../homefiles/hgignore_global;
  };

  ".ideavimrc" = {
    source = ../../homefiles/ideavimrc;
  };

};

  # Install packages using Home Manager
  home.packages = with pkgs; [
    age             # Modern encryption tool
    bat             # Cat clone with syntax highlighting
    # bitwarden-cli   # Command-line interface for Bitwarden
    bruno           # API client
    chezmoi         # Dotfiles manager
    curl            # URL retrieval utility
    direnv
    discord         # Voice and text chat app
    docker          # Containerization platform
    fzf             # Command-line fuzzy finder
    gcc
    ghq             # Remote repository management
    git             # Version control system
    gnupg           # GNU Privacy Guard
    google-chrome   # Web browser
    imagemagick     # Image manipulation tools
    inetutils       # Network utilities
    inkscape        # Vector graphics editor
    jq              # Command-line JSON processor
    meld            # Visual diff and merge tool
    neofetch        # System information tool
    oh-my-posh      # Prompt theme engine
    ripgrep         # Fast grep alternative
    rsync           # File synchronization tool
    slack           # Team communication tool
    sops
    spotify         # Music streaming service
    wget            # Network downloader
    wireguard-tools # VPN tools
    yq-go           # YAML processor
    z-lua           # Directory jumper
    # zed-editor    # Broken on Darwin: https://github.com/NixOS/nixpkgs/pull/303233#issuecomment-2048650618
    zoom-us
  ];
  # Set session variables
  home.sessionVariables = {
    TERM = "xterm-kitty";
    PAGER = "less";
    CLICOLOR = 1;
    EDITOR = "nvim";
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    GHQ_ROOT = "$HOME/Source";
    NIX_SHELL_NAME = "unknown";
    SOPS_AGE_KEY_FILE = "$HOME/.age/personal-key.txt";
  };

  # Define shell aliases
  home.shellAliases = {
    man = "batman";
    llat = "eza -la --sort=modified";
    llart = "eza -lar --sort=modified";
    lg = "lazygit";
    ranger = "yazi";
  };

  # Set Home Manager state version
  home.stateVersion = "24.05";

  # Enable and configure various programs
  programs.atuin.enable = true;  # Shell history sync
  programs.bat.enable = true;
  programs.bat.extraPackages = with pkgs.bat-extras; [ batgrep batman batpipe prettybat ];
  programs.bottom.enable = true;  # System monitor
  programs.eza.enable = true;     # Modern ls replacement
  programs.eza.extraOptions = [
    "--group-directories-first"
    "--header"
  ];
  programs.eza.git = true;
  programs.eza.icons = true;

  programs.fish.shellAbbrs = {
    cm = "chezmoi";
  };
  programs.fzf.enable = true;     # Fuzzy finder

  # Git configuration
  programs.git.enable = true;
  programs.git.extraConfig = {
    credential.helper = "store";
    diff.tool = "meld";
    difftool.prompt = false;
    "difftool \"meld\"".cmd = "meld \"$LOCAL\" \"$REMOTE\"";
    init.defaultBranch = "master";
    pull.rebase = true;
  };
  programs.git.ignores = [
    "*~"
    ".DS_Store"
    "*.swp"
  ];
  programs.git.lfs.enable = true;
  programs.git.userEmail = "fred.drake@gmail.com";
  programs.git.userName = "Fred Drake";

  # Enable other utilities
  programs.jq.enable = true;      # JSON processor

  # TODO: implement declarative settings
  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    gui.theme = {
      lightTheme = true;
    };
  };

  # Neovim configuration
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;

  # Yazi file manager
  programs.yazi.enable = true;

  # Additional file configurations
  home.file = {
    ".config/docker".source = ./docker;
  };
}
