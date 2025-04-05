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
      source ~/.llm_api_keys.env.backup
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
        exec ${pkgs.nushell}/bin/nu
      elif [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
      fi
    '';
  };
}
