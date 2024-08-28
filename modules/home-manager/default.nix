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
    "*.{toml,js,py,nix}" = {
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
    imagemagick
    inetutils
    inkscape
    jq
    lazygit
    mas
    meld
    neofetch
    oh-my-posh
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
    TERM = "xterm-kitty";
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
  programs.kitty.enable = true;
  programs.kitty.font = {
      name = "MesloLGS NF";
      size = 14.0;
  };
  programs.kitty.keybindings = {
    "super+alt+enter" = "launch --cwd=current";

    "super+alt+w" = "close_window";
    "super+alt+l" = "next_window";
    "super+alt+h" = "previous_window";
    "super+alt+1" = "first_window";
    "super+alt+2" = "second_window";
    "super+alt+3" = "third_window";
    "super+alt+4" = "fourth_window";
    "super+alt+5" = "fifth_window";
    "super+alt+6" = "sixth_window";
    "super+alt+7" = "seventh_window";
    "super+alt+8" = "eighth_window";
    "super+alt+9" = "ninth_window";
    "super+alt+0" = "tenth_window";
    "super+alt+o" = "next_layout";

    "super+l" = "next_tab";
    "super+h" = "previous_tab";
    "super+enter" = "new_tab";
    "super+t" = "new_tab";
    "super+1" = "goto_tab 1";
    "super+2" = "goto_tab 2";
    "super+3" = "goto_tab 3";
    "super+4" = "goto_tab 4";
    "super+5" = "goto_tab 5";
    "super+6" = "goto_tab 6";
    "super+7" = "goto_tab 7";
    "super+8" = "goto_tab 8";
    "super+9" = "goto_tab 9";

    "super+plus" = "change_font_size all +2.0";
    "super+minus" = "change_font_size all -2.0";
  };
  programs.kitty.settings = {
    "window_margin_width" = 10;
    "single_window_margin_width" = 0;
    "background_image" = "~/Pictures/night-desert.png";
    "background_image_layout" = "scaled";
    "window_border_width" = 2;
    "background_tint" = "0.8";
    "background_tint_gaps" = -10;
    "enabled_layouts" = "tall:full_size=2, grid, *";
    "tab_bar_style" = "powerline";
    "tab_powerline_style" = "round";
    "tab_title_template" = "{index}: {title}";
  };
  programs.kitty.shellIntegration.enableZshIntegration = true;
  # programs.kitty.theme = "";
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;
  programs.yazi.enable = true;
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
    # "romkatv/powerlevel10k"
    "hlissner/zsh-autopair"
    "olets/zsh-abbr"
  ];
  # programs.zsh.initExtra = ''
  #   [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # '';
  programs.zsh.initExtra = ''
    if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
      eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
    fi
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


