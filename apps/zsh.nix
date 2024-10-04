# Zsh Configuration
#
# This file defines the configuration for the Zsh shell.
# It includes settings for:
#   - Enabling Zsh
#   - Antidote plugin manager and its plugins
#   - Oh My Posh prompt initialization
#   - Custom PATH modifications
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    antidote = {
      enable = true;
      plugins = [];
    };
    # Add local bin to path, and ensure that oh-my-posh doesn't get initialized in Apple Terminal
    initExtra = ''
      PATH=~/bin:$PATH
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        # eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
        exec ${pkgs.fish}/bin/fish
      fi


    '';
  };
}
