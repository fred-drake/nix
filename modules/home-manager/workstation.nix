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
{
  pkgs,
  hostArgs,
  pkgs-stable,
  pkgs-unstable,
  pkgs-fred-unstable,
  pkgs-fred-testing,
  lib,
  vars,
  ...
}: let
  vscode-config = (import ../../apps/vscode/global-configuration.nix) {inherit pkgs lib;};
in {
  programs = {
    fish.enable = true;
    oh-my-posh = {
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      useTheme = "craver";
    };
  };
  home.file =
    {
      "Pictures" = {
        source = ../../homefiles/Pictures;
        recursive = true;
      };

      ".ideavimrc" = {source = ../../homefiles/ideavimrc;};

      "bin/glance" = {
        text = ''
          #!/usr/bin/env bash
          source ~/.config/glance/glance.env
          ${pkgs.glance}/bin/glance -config ~/.config/glance/glance.json
        '';
        executable = true;
      };

      ".config/glance/glance.json" = {
        text = builtins.toJSON (import ./files/glance-config.nix);
      };

      ".cursor/mcp.json" = {
        text = builtins.toJSON (import ./files/mcp-server-config.nix);
      };

      ".codeium/windsurf/mcp_config.json" = {
        text = builtins.toJSON (import ./files/mcp-server-config.nix);
      };
    }
    // (
      if pkgs.stdenv.isDarwin
      then {
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
  home.packages =
    (with pkgs; [
      chafa # Image resizer
      docker-compose # Compose multiple containers
      duf # Disk usage analyzer
      eza # File explorer
      ghq # Remote repository management
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
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = vscode-config.globalExtensions;
      })
    ])
    ++ (
      # Packages that go on all workstations except the linux/aarch64 architectures
      if !(pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64)
      then
        with pkgs; [
          discord # Voice and text chat app
          slack # Team communication tool
          spotify # Music streaming service
          (pkgs.writeShellScriptBin "cursor" ''
            EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
            exec ${pkgs.code-cursor}/bin/cursor --extensions-dir $EXT_DIR "$@"
          '')
          (pkgs.writeShellScriptBin "windsurf" ''
            EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
            exec ${pkgs.windsurf}/bin/windsurf --extensions-dir $EXT_DIR "$@"
          '')
        ]
      else []
    )
    ++ (
      # Development packages -- need these at the home-manager level for remote SSH development
      if hostArgs.hostName == "fredpc" || hostArgs.hostName == "nixosaarch64vm"
      then
        (with pkgs; [
          # MCP
          nodejs_22
          uv

          # Go
          go
          gopls
          gotools
          go-tools

          # Nix
          alejandra
          nixd
        ])
      else []
    )
    ++ (with pkgs-unstable; [])
    ++ (with pkgs-fred-unstable; [])
    ++ (with pkgs-fred-testing; [])
    ++ (with pkgs-stable; []);

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
