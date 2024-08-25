{ pkgs, lib, ... }: {
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
    "*.{js,py,nix}" = {
      indent_size = 2;
    };
  };
  home.activation.tideConfig = lib.hm.dag.entryAfter["writeBoundary"] ("${pkgs.fish}/bin/fish ~/.config/nix/modules/home-manager/tideconfig.fish");
  home.packages = with pkgs; [
    age
    alacritty
    bartender
    bat
    bitwarden-cli
    bruno
    chezmoi
    curl
    discord
    docker
    fzf
    ghq
    git
    gnupg
    google-chrome
    inetutils
    inkscape
    jq
    lazygit
    mas
    ripgrep
    rsync
    slack
    spotify
    vscode
    wget
    wireguard-tools
    yq-go
    z-lua
  ];
  home.sessionVariables = {
    TERM = "xterm-256color";
    PAGER = "less";
    CLICOLOR = 1;
    EDITOR = "nvim";
    HOMEBREW_PREFIX = "/opt/homebrew";
	  HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
	  HOMEBREW_REPOSITORY = "/opt/homebrew";
  };
  home.stateVersion = "24.05";
  programs.alacritty = import ./alacritty.nix;
  programs.atuin.enable = true;
  programs.bat.enable = true;
  programs.bat.extraPackages = with pkgs.bat-extras; [ batgrep batman batpipe prettybat ];
  programs.bottom.enable = true;
  programs.eza.enable = true;
  programs.eza.extraOptions = [
    "--group-directories-first"
    "--header"
  ];
  programs.eza.git = true;
  programs.eza.icons = true;
  programs.fish = import ./fish.nix { inherit pkgs; };
  programs.fzf.enable = true;
  programs.git.enable = true;
  programs.git.lfs.enable = true;
  programs.git.userEmail = "fred.drake@gmail.com";
  programs.git.userName = "fred-drake";
  programs.jq.enable = true;
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;
  programs.tmux = import ./tmux.nix { inherit pkgs; };
  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
  targets.darwin.defaults."com.apple.Safari".AutoFillCreditCardData = false;
  targets.darwin.defaults."com.apple.Safari".AutoFillPasswords = false;
  targets.darwin.defaults."com.apple.Safari".IncludeDevelopMenu = true;
  targets.darwin.defaults."com.apple.desktopservices".DSDontWriteNetworkStores = true;
  targets.darwin.defaults."com.apple.desktopservices".DSDontWriteUSBStores = true;
  targets.darwin.defaults."com.apple.finder".FXRemoveOldTrashItems = true;
  targets.darwin.search = "Google";
}

