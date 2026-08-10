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
    # Re-export in nested shells where Home Manager's session-vars marker is
    # inherited without the variables (notably Herdr panes).
    envExtra = ''
      export PI_SUBAGENT_MUX=herdr
      export PI_SUBAGENT_HERDR_PLACEMENT=tab
    '';
    # Add local bin to path, and ensure that oh-my-posh doesn't get initialized in Apple Terminal
    initContent = ''
      PATH=~/bin:$PATH
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
        # exec ${pkgs.fish}/bin/fish
      elif [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
      fi
    '';
  };
}
