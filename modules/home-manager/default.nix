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
  hostArgs,
  inputs,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
  vscode-config = (import ../../apps/vscode/global-configuration.nix) {inherit pkgs lib;};
  # Use wrapped mermaid-cli with platform-appropriate Chrome/Chromium
  mermaid-cli-wrapped = pkgs.callPackage ../../apps/mermaid-cli-wrapped.nix {
    inherit (pkgs) stdenv;
  };
  ccstatusline = pkgs.callPackage ../../apps/ccstatusline.nix {
    npm-packages = import ../../apps/fetcher/npm-packages.nix;
  };
  agent-browser = pkgs.callPackage ../../apps/agent-browser.nix {
    npm-packages = import ../../apps/fetcher/npm-packages.nix;
    inherit (pkgs) playwright-driver;
  };
  discordo-config = ''
    [theme.title]
    alignment = "left"
    normal_style = { attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }

    [theme.footer]
    alignment = "left"
    normal_style = { attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }

    [theme.border]
    enabled = true
    padding = [0, 0, 1, 1]
    normal_style = { foreground = "purple", attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }
    normal_set = "round"
    active_set = "round"

    [theme.guilds_tree]
    auto_expand_folders = true
    graphics = true
    graphics_color = "purple"

    [theme.messages_list]
    reply_indicator = ">"
    forwarded_indicator = "<"
    mention_style = { foreground = "yellow", attributes = "bold" }
    emoji_style = { foreground = "yellow" }
    url_style = { foreground = "aqua" }
    attachment_style = { foreground = "aqua" }
    message_style = { attributes = "dim" }
    selected_message_style = { attributes = "reverse" }
  '';
  # Build tdd-guard with nixpkgs-stable to avoid npm 10+ ENOTCACHED issues
  pkgsStable = import inputs.nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  tdd-guard = pkgsStable.callPackage ../../apps/tdd-guard.nix {};
in {
  # Import additional configuration files
  imports = [
    ../../apps/zsh.nix
    ../../apps/fish.nix
    ../../apps/tmux.nix
    ../../apps/nixvim
    ./tmux-windev-settings.nix
    ./secrets.nix
    ./claude-code.nix
  ];

  # Ensure .ssh directory has correct permissions
  home.activation = {
    ssh-restrict = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${home}/.ssh
      chmod 700 ${home}/.ssh
    '';
    ssh-authorized-keys-copy = lib.hm.dag.entryAfter ["linkGeneration"] ''
      # Remove symlink and create actual file for SSH authorized_keys
      rm -f ${home}/.ssh/authorized_keys
      echo "${config.soft-secrets.workstation.ssh.authorized-keys}" > ${home}/.ssh/authorized_keys
      chmod 600 ${home}/.ssh/authorized_keys
    '';
    zed-settings-copy = lib.hm.dag.entryAfter ["writeBoundary"] ''
      cp -f ${home}/.config/zed/settings-original.json ${home}/.config/zed/settings.json
      cp -f ${home}/.config/zed/keymap-original.json ${home}/.config/zed/keymap.json
    '';
  };

  # Enable and configure EditorConfig
  editorconfig = {
    enable = true;
    settings = {
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
  };

  home = {
    file =
      {
        # Note: authorized_keys is handled by home.activation to ensure it's a real file, not a symlink
        "ssh-config" = {
          text = config.soft-secrets.workstation.ssh.config;
          target = ".ssh/config";
        };

        ".ssh" = {
          source = ../../homefiles/ssh;
          recursive = true;
        };

        ".config" = {
          source = ../../homefiles/config;
          recursive = true;
        };

        # Ghostty configuration (base config for all hosts)
        ".config/ghostty/config".text = ''
          app-notifications = no-clipboard-copy
        '';

        "Pictures" = {
          source = ../../homefiles/Pictures;
          recursive = true;
        };

        ".hgignore_global" = {source = ../../homefiles/hgignore_global;};
        ".ideavimrc" = {source = ../../homefiles/ideavimrc;};
        ".wezterm.lua" = {source = ../../homefiles/wezterm.lua;};
      }
      // (
        if pkgs.stdenv.isDarwin
        then {
          "Library/Application Support/discordo/config.toml" = {
            text = discordo-config;
          };
          ".config/discordo/config.toml" = {
            text = discordo-config;
          };
          "Library/Application Support/Code/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          "Library/Application Support/Code/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
          "Library/Application Support/Cursor/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          "Library/Application Support/Cursor/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
          "Library/Application Support/Windsurf/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          "Library/Application Support/Windsurf/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
        }
        else {
          ".config/discordo/config.toml" = {
            text = discordo-config;
          };
          ".config/Code/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          ".config/Code/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
          ".config/Cursor/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          ".config/Cursor/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
          ".config/Windsurf/User/settings.json" = {
            text = builtins.toJSON vscode-config.globalSettings;
          };
          ".config/Windsurf/User/keybindings.json" = {
            text = builtins.toJSON vscode-config.globalKeyBindings;
          };
        }
      );

    # Install packages using Home Manager
    packages =
      [agent-browser] # Playwright browser automation
      ++ (with pkgs; [
        age # Modern encryption tool
        bat # Cat clone with syntax highlighting
        btop # System monitor
        ccstatusline # Claude Code statusline
        chafa # Image to terminal converter
        curl # URL retrieval utility
        delta # Syntax-highlighting pager
        devenv # Development environment manager
        direnv # Environment variable manager
        discordo
        docker-compose # Compose multiple containers
        dua # Disk usage analyzer with interactive mode
        duf # Disk usage overview
        eza # File explorer
        fastfetch # System information tool
        fd # Fast directory walker
        fzf # Command-line fuzzy finder
        ghq # Remote repository management
        git # Version control system
        gnupg # GNU Privacy Guard
        hclfmt # HCL formatter
        imagemagick # Image manipulation tools
        highlight # Syntax highlighting
        imgcat # Image viewer
        inetutils # Network utilities
        jq # Command-line JSON processor
        kind # Kubernetes cluster manager
        kondo # Cleans node_modules, target, build, and friends from your projects.
        kubectl # Kubernetes command-line tool
        lazydocker # Docker CLI with auto-completion and syntax highlighting
        llama-cpp # Text generation
        localsend # Local network file sharing
        lsof # List open files
        meld # Visual diff and merge tool
        minio-client # MinIO object storage client
        ncdu # NCurses disk usage analyzer
        neofetch # System information display
        nixd # Nix language server
        oh-my-posh # Prompt theme engine
        openssl # Cryptography toolkit
        presenterm # Presentation in markdown
        ripgrep # Fast grep alternative
        rsync # File synchronization tool
        skim # Fuzzy finder
        sops # Secret management tool
        stc-cli # Syncthing CLI
        syncthing # File synchronization tool
        tdd-guard # Test-driven development watcher
        tldr # Simplified man pages
        tmux # Terminal multiplexer
        tmux-mem-cpu-load # CPU and memory usage monitor
        tokei # Code statistics tool
        unzip # ZIP archive extractor
        # wezterm
        wiki-tui # Wikipedia TUI
        wireguard-tools # VPN tools
        wget # Network downloader
        woodpecker-cli # Woodpecker CI CLI tool
        yq-go # YAML processor
        yt-dlp # Video downloader
        # (pkgs.vscode-with-extensions.override {
        #   vscodeExtensions = vscode-config.globalExtensions;
        # })
      ])
      ++ (
        # Packages that are on workstations that are more heavily used
        # e.g. not wasting space on Laisa's mac-mini
        if
          hostArgs.hostName
          == "fredpc"
          || hostArgs.hostName == "macbook-pro"
          || hostArgs.hostName == "mac-studio"
        then
          with pkgs; [
            discord # Voice and text chat app
            slack # Team communication tool
            spotify # Music streaming service
            inkscape # Vector graphics editor
            podman # Container runtime
            podman-tui # Podman terminal UI
          ]
        else []
      )
      ++ (
        if pkgs.stdenv.hostPlatform.isDarwin
        then [
          mermaid-cli-wrapped # Mermaid CLI with Chrome support (Darwin only)
          (pkgs.writeShellScriptBin "windsurf-code" ''
            EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
            exec /opt/homebrew/bin/windsurf --extensions-dir $EXT_DIR "$@"
          '')
        ]
        else [
          pkgs.wl-clipboard # Wayland clipboard for helix and other apps
        ]
        # REMOVING THIS FOR NOW -- Using Claude Code and NVIM over Windsurf
        # )
        # ++ (
        #   # Development packages -- need these at the home-manager level for remote SSH development
        #   if hostArgs.hostName == "fredpc" || hostArgs.hostName == "nixosaarch64vm"
        #   then
        #     (with pkgs; [
        #       # MCP
        #       nodejs_22
        #       uv
        #
        #       # Go
        #       go
        #       gopls
        #       gotools
        #       go-tools
        #
        #       # Nix
        #       alejandra
        #       nixd
        #     ])
        #   else []
      );

    # Set session variables
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      TERM = "xterm-256color";
      PAGER = "less";
      CLICOLOR = 1;
      SOPS_AGE_KEY_FILE = "$HOME/.age/personal-key.txt";
      GHQ_ROOT = "$HOME/Source";
      PODMAN_COMPOSE_WARNING_LOGS = "false";
    };

    # Define shell aliases
    shellAliases = {
      man = "batman";
      lg = "lazygit";
      ranger = "yy";
      vpn-brainrush-stage-up = "sudo wg-quick up $HOME/.config/wireguard/brainrush-stage.conf";
      vpn-brainrush-stage-down = "sudo wg-quick down $HOME/.config/wireguard/brainrush-stage.conf";
    };

    # Set Home Manager state version -- DONT touch this
    stateVersion = "24.05";
  };

  # Enable and configure various programs
  programs = {
    atuin.enable = true; # Shell history sync
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batgrep
        batman
        batpipe
        prettybat
      ];
    };
    bottom.enable = true; # System monitor
    carapace.enable = true;
    direnv.enable = true;

    fish.enable = true;
    fzf = {
      enable = true; # Fuzzy finder
      changeDirWidgetCommand = "fd --type d";
      changeDirWidgetOptions = ["--preview 'tree -C {} | head -200'"];
      defaultCommand = "fd --type f";
      fileWidgetCommand = "fd --type f";
      fileWidgetOptions = ["--preview 'head {}'"];
      historyWidgetOptions = ["--sort" "--exact"];
    };

    # Git configuration
    git = {
      enable = true;
      settings = {
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
        user = {
          email = "fred.drake@gmail.com";
          name = "Fred Drake";
        };
      };
      ignores = ["*~" ".DS_Store" "*.swp"];
      lfs.enable = true;
    };

    # Helix editor configuration
    helix = {
      enable = true;
      defaultEditor = true;

      # Custom theme with transparent background so tmux window-style shows through
      themes = {
        tokyonight_transparent = {
          inherits = "tokyonight";
          "ui.background" = {};
          "ui.cursorline.primary" = {};
          "ui.statusline" = {fg = "#a9b1d6";};
          "ui.statusline.inactive" = {fg = "#565f89";};
          "ui.bufferline" = {fg = "#565f89";};
          "ui.bufferline.active" = {fg = "#a9b1d6";};
        };
      };

      settings = {
        theme = "tokyonight_transparent";

        editor = {
          line-number = "relative";
          mouse = true;
          cursorline = true;
          rulers = [100];
          color-modes = true;
          bufferline = "multiple";
          true-color = true;

          auto-save = {
            focus-lost = true;
            after-delay = {
              enable = true;
              timeout = 500;
            };
          };

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          file-picker.hidden = false;

          indent-guides = {
            render = true;
            character = "│";
          };

          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };

          statusline = {
            left = ["mode" "spinner" "file-name" "file-modification-indicator"];
            center = [];
            right = ["diagnostics" "selections" "register" "position" "file-encoding"];
            separator = "│";
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
          };

          whitespace.render.tab = "all";
          whitespace.render.newline = "none";

          soft-wrap.enable = true;
        };

        keys.normal = {
          K = "hover";
          C-s = ":w";
          C-q = ":q";
          C-h = ":bp";
          C-l = ":bn";
          # Clipboard operations - yank, delete, change all use system clipboard
          y = "yank_to_clipboard";
          d = ["yank_to_clipboard" "delete_selection_noyank"];
          c = ["yank_to_clipboard" "change_selection_noyank"];
        };

        keys.insert = {
          j = {k = "normal_mode";};
        };
      };

      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter.command = "alejandra";
            formatter.args = ["-q"];
          }
        ];
      };
    };

    # Enable other utilities
    jq.enable = true; # JSON processor

    lazygit = {
      enable = true;
      settings = {
        git.pagers = [{pager = "delta --dark --paging=never";}];
        gui.theme = {lightTheme = true;};
      };
    };

    # We pull neovim through github:fred-drake/neovim now
    neovim.enable = false;

    oh-my-posh = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      settings = builtins.fromJSON (builtins.readFile ../../apps/oh-my-posh/config.json);
    };

    # Yazi file manager
    yazi.enable = true;

    zoxide.enable = true;
  };
}
