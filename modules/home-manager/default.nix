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
    meld
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
    GHQ_ROOT = "$HOME/Source";
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
  programs.fzf.enable = true;
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
  programs.git.userName = "fred-drake";
  programs.jq.enable = true;
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;
  programs.zsh.enable = true;
  programs.zsh.antidote.enable = true;
  programs.zsh.antidote.plugins = [
    "mattmc3/ez-compinit"
    "zsh-users/zsh-autosuggestions"
    "ohmyzsh/ohmyzsh path:plugins/sudo"
    "ohmyzsh/ohmyzsh path:plugins/dirhistory"
    "ohmyzsh/ohmyzsh path:plugins/z"
    "ohmyzsh/ohmyzsh path:plugins/macos"
    "jeffreytse/zsh-vi-mode"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
    "MichaelAquilina/zsh-you-should-use"
    "romkatv/powerlevel10k"
    "hlissner/zsh-autopair"
    "olets/zsh-abbr"
  ];
  programs.zsh.initExtra = ''
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  '';
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


