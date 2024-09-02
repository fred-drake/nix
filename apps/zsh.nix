# Zsh Configuration
#
# This file defines the configuration for the Zsh shell.
# It includes settings for:
#   - Enabling Zsh
#   - Antidote plugin manager and its plugins
#   - Oh My Posh prompt initialization
#   - Custom PATH modifications

{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    antidote = {
      enable = true;
      plugins = [
        "mattmc3/ez-compinit"                    # Simplifies and speeds up Zsh completion initialization
        "zsh-users/zsh-autosuggestions"          # Suggests commands as you type based on history and completions
        "ohmyzsh/ohmyzsh path:plugins/sudo"      # Allows you to prefix your current command with sudo by pressing esc twice
        "ohmyzsh/ohmyzsh path:plugins/dirhistory" # Adds keyboard shortcuts for navigating directory history
        "ohmyzsh/ohmyzsh path:plugins/z"         # Tracks your most used directories and allows quick navigation
        "ohmyzsh/ohmyzsh path:plugins/macos"     # Provides macOS-specific aliases and functions
        "jeffreytse/zsh-vi-mode"                 # Adds Vi mode to Zsh
        "zsh-users/zsh-syntax-highlighting"      # Provides syntax highlighting for the shell command line
        "zsh-users/zsh-completions"              # Adds additional completion definitions for Zsh
        "MichaelAquilina/zsh-you-should-use"     # Reminds you to use existing aliases for commands you type
        "hlissner/zsh-autopair"                  # Automatically pairs quotes, brackets, etc.
        "olets/zsh-abbr"                         # Manages abbreviations for frequently used commands
      ];
    };
    # Add local bin to path, and ensure that oh-my-posh doesn't get initialized in Apple Terminal
    initExtra = ''
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
      fi

      PATH=~/bin:$PATH
    '';
  };
}
