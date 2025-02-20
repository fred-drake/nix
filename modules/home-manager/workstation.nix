# Home Manager Configuration for Workstations
#
# This file defines the Home Manager configuration for all workstation systems.
# It includes:
#   - Package installations
#   - Program configurations (git, kitty, neovim, zsh, etc.)
#   - Environment variables and shell aliases
#   - macOS-specific settings and defaults
#
# The configuration uses the Nix package manager and various Nix-related tools
# to manage the user environment in a declarative and reproducible manner.
# Home Manager configuration for macOS
{pkgs, ...}: {
  home.file = {
    "Pictures" = {
      source = ../../homefiles/Pictures;
      recursive = true;
    };

    ".ideavimrc" = {source = ../../homefiles/ideavimrc;};
  };

  # Install packages using Home Manager
  home.packages = with pkgs; [
    aider-chat # AI Chat client
    chafa # Image resizer
    discord # Voice and text chat app
    docker-compose # Compose multiple containers
    duf # Disk usage analyzer
    gcc # C compiler
    ghq # Remote repository management
    google-chrome # Web browser
    hclfmt # HCL formatter imagemagick # Image manipulation tools
    imgcat # Image viewer
    inkscape # Vector graphics editor
    kind # Kubernetes cluster manager
    kondo # Cleans node_modules, target, build, and friends from your projects.
    kubectl # Kubernetes command-line tool
    lazydocker # Docker CLI with auto-completion and syntax highlighting
    llama-cpp # Text generation
    meld # Visual diff and merge tool
    oh-my-posh # Prompt theme engine
    podman
    podman-tui
    slack # Team communication tool
    spotify # Music streaming service
    spotify-player # Spotify client
    stc-cli # Syncthing CLI
    syncthing # File synchronization tool
    tldr # Documentation tool
    tmux # Terminal multiplexer
    tmuxinator # Tmux session manager
    tmux-mem-cpu-load # CPU and memory usage monitor
    tokei # Code statistics tool
    wireguard-tools # VPN tools
    yt-dlp # Video downloader
    zoom-us # Video conferencing tool
  ];

  # Set session variables
  home.sessionVariables = {
    GHQ_ROOT = "$HOME/Source";
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };

  # Define shell aliases
  home.shellAliases = {
  };

  # Enable and configure various programs
  programs.fish.shellAbbrs = {
  };
}
