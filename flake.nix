{
  description = "Default flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: {
    darwinConfigurations.Freds-MacBook-Pro = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
      modules = [
        ({ pkgs, ... }: {
          # Darwin preferences and configuration
          # environment.darwinConfig = "$HOME/nix/flake.nix";
          environment.shells = with pkgs; [ bash zsh fish ];
          environment.loginShell = pkgs.fish;
          environment.systemPackages = [ pkgs.coreutils ];
          environment.systemPath = [ "/opt/homebrew/bin" ];
          environment.pathsToLink = [ "/Applications" ];
          fonts.packages = [(pkgs.nerdfonts.override { fonts = [ "Meslo" ]; }) ];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          programs.bash = {
            interactiveShellInit = ''
              if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
              then
                shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
              fi
            '';
          };
          programs.fish.enable = true;
          programs.tmux.enableMouse = true;
          programs.zsh.enable = true;
          services.nix-daemon.enable = true;
          system.defaults.dock.autohide = true;
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
          system.defaults.NSGlobalDomain.KeyRepeat = 1;
          system.keyboard.enableKeyMapping = true;
          system.keyboard.remapCapsLockToControl = true;
          system.stateVersion = 4;
	  users.knownUsers = [ "fdrake" ];
	  users.users.fdrake.uid = 501;
          users.users.fdrake.home = "/Users/fdrake";
          users.users.fdrake.shell = pkgs.fish;
        })
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.fdrake.imports = [
              ({ pkgs, ... }: {
                home.packages = with pkgs; [ git neovim ];
                home.sessionVariables = {
                  PAGER = "less";
                  CLICOLOR = 1;
                  EDITOR = "nvim";
                };
                home.stateVersion = "24.05";
                programs.fish.enable = true;
                programs.tmux.enable = true;
              })
            ];
          };
        }
      ];
    };
  };
}
