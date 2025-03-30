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
{
  pkgs,
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
in {
  # Import additional configuration files
  imports = [
    ../../apps/zsh.nix
    ../../apps/fish.nix
    ../../apps/nushell.nix
    ../../apps/tmux.nix
    ../../apps/nixvim
    ./secrets.nix
  ];

  # Ensure .ssh directory has correct permissions
  home.activation = {
    ssh-restrict = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${home}/.ssh
      chmod 700 ${home}/.ssh
    '';
  };

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
    "ssh-authorized-keys" = {
      text = config.soft-secrets.workstation.ssh.authorized-keys;
      target = ".ssh/authorized_keys";
    };
    "ssh-config" = {
      text = config.soft-secrets.workstation.ssh.config;
      target = ".ssh/config";
    };
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
    dua
    duf # Disk usage analyzer
    fastfetch # System information tool
    fd # Fast directory walker
    fzf # Command-line fuzzy finder
    git # Version control system
    gnupg # GNU Privacy Guard
    highlight # Syntax highlighting
    inetutils # Network utilities
    jq # Command-line JSON processor
    oh-my-posh # Prompt theme engine
    ripgrep # Fast grep alternative
    rsync # File synchronization tool
    skim # Fuzzy finder
    sops # Secret management tool
    wget # Network downloader
    yq-go # YAML processor
  ];
  # Set session variables
  home.sessionVariables = {
    TERM = "xterm-256color";
    PAGER = "less";
    CLICOLOR = 1;
    EDITOR = "nvim";
    SOPS_AGE_KEY_FILE = "$HOME/.age/personal-key.txt";
  };

  # Define shell aliases
  home.shellAliases = {
    man = "batman";
    lg = "lazygit";
    ranger = "yy";
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
  programs.carapace.enable = true;
  programs.direnv.enable = true;

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

  programs.oh-my-posh.enable = true;

  # programs.pay-respects.enable = true;

  # Yazi file manager
  programs.yazi.enable = true;

  programs.zoxide.enable = true;
}
