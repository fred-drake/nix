# Home Manager Configuration for macOS
#
# This file defines the Home Manager configuration for macOS systems.
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
  # Import additional configuration files
  imports = [../../apps/kitty.nix ../../apps/zsh.nix ../../apps/fish.nix ../../apps/tmux.nix];

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
    "*.{toml,js,nix,yaml}" = {indent_size = 2;};
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

    ".hgignore_global" = {source = ../../homefiles/hgignore_global;};
  };

  # Install packages using Home Manager
  home.packages = with pkgs; [
    age # Modern encryption tool
    bat # Cat clone with syntax highlighting
    btop # System monitor
    chezmoi # Dotfiles manager
    curl # URL retrieval utility
    delta # Syntax-highlighting pager
    devenv # Development environment manager
    direnv # Environment variable manager
    duf # Disk usage analyzer
    fastfetch # System information tool
    fd # Fast directory walker
    fzf # Command-line fuzzy finder
    git # Version control system
    gnupg # GNU Privacy Guard
    inetutils # Network utilities
    jq # Command-line JSON processor
    kind # Kubernetes cluster manager
    kubectl # Kubernetes command-line tool
    oh-my-posh # Prompt theme engine
    ripgrep # Fast grep alternative
    rsync # File synchronization tool
    sops # Secret management tool
    tmuxinator # Tmux session manager
    wget # Network downloader
    yq-go # YAML processor
    zoxide # Directory jumper
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
    SOPS_AGE_KEY_FILE = "$HOME/.age/personal-key.txt";
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };

  # Define shell aliases
  home.shellAliases = {
    man = "batman";
    llat = "eza -la --sort=modified";
    llart = "eza -lar --sort=modified";
    lg = "lazygit";
    ranger = "yazi";
    cat = "bat --paging=never --style=plain";
  };

  # Set Home Manager state version
  home.stateVersion = "24.05";

  # Enable and configure various programs
  programs.atuin.enable = true; # Shell history sync
  programs.bat.enable = true;
  programs.bat.extraPackages = with pkgs.bat-extras; [
    batgrep
    batman
    batpipe
    prettybat
  ];
  programs.bottom.enable = true; # System monitor
  programs.eza.enable = true; # Modern ls replacement
  programs.eza.extraOptions = ["--group-directories-first" "--header"];
  programs.eza.git = true;
  programs.eza.icons = "auto";

  programs.fish.shellAbbrs = {
    cm = "chezmoi";
    du = "duf";
    k = "kubectl";
    mc = "ranger";
    t = "tmuxinator";
    telnet = "nc -zv";
  };

  programs.fzf = {
    enable = true; # Fuzzy finder
    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = ["--preview 'tree -C {} | head -200'"];
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = ["--preview 'head {}'"];
    historyWidgetOptions = ["--sort" "--exact"];
  };

  # Git configuration
  programs.git.enable = true;
  programs.git.extraConfig = {
    core.pager = "delta";
    credential.helper = "store";
    delta = {
      features = "decorations";
      interactive.keep-plus-minus-markers = false;
      decorations = {
        commit-decoration-style = "blue ol";
        commit-style = "raw";
        file-style = "omit";
        hunk-header-decoration-style = "blue box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "#067a00";
        hunk-header-style = "file line-number syntax";
      };
    };
    diff.tool = "meld";
    difftool.prompt = false;
    "difftool \"meld\"".cmd = ''meld "$LOCAL" "$REMOTE"'';
    init.defaultBranch = "master";
    interactive.diffFilter = "delta --color-only --features=interactive";
    pull.rebase = true;
  };
  programs.git.ignores = ["*~" ".DS_Store" "*.swp"];
  programs.git.lfs.enable = true;
  programs.git.userEmail = "fred.drake@gmail.com";
  programs.git.userName = "Fred Drake";

  # Enable other utilities
  programs.jq.enable = true; # JSON processor

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    git.paging = {pager = "delta --dark --paging=never";};
    gui.theme = {lightTheme = true;};
  };

  # We pull neovim through github:fred-drake/neovim now
  programs.neovim.enable = false;

  # Yazi file manager
  programs.yazi.enable = true;
}
