{...}: {
  imports = [
    ../../../apps/zsh.nix
    ../../../apps/fish.nix
  ];

  programs = {
    fish.enable = true;

    fzf = {
      enable = true;
      changeDirWidgetCommand = "fd --type d";
      changeDirWidgetOptions = ["--preview 'tree -C {} | head -200'"];
      defaultCommand = "fd --type f";
      fileWidgetCommand = "fd --type f";
      fileWidgetOptions = ["--preview 'head {}'"];
      historyWidgetOptions = ["--sort" "--exact"];
    };

    zoxide.enable = true;
    carapace.enable = true;

    oh-my-posh = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      settings = builtins.fromJSON (builtins.readFile ../../../homefiles/config/oh-my-posh/config.json);
    };
  };

  home = {
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

    shellAliases = {
      man = "batman";
      lg = "lazygit";
      ranger = "yy";
      vpn-brainrush-stage-up = "sudo wg-quick up $HOME/.config/wireguard/brainrush-stage.conf";
      vpn-brainrush-stage-down = "sudo wg-quick down $HOME/.config/wireguard/brainrush-stage.conf";
    };
  };
}
