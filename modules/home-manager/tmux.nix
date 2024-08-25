{ pkgs, ... }: {
  enable = true;
  baseIndex = 1;
  escapeTime = 0;
  extraConfig = ''
    unbind %
    bind | split-window -h

    unbind '"'
    bind - split-window -v

    unbind r
    bind r source-file ~/.config/tmux/tmux.conf

    bind -r j resize-pane -D 5
    bind -r k resize-pane -U 5
    bind -r l resize-pane -R 5
    bind -r h resize-pane -L 5

    bind -r m resize-pane -Z

    set -g detach-on-destroy off

    unbind -T copy-mode-vi MouseDragEnd1Pane

    # Smart pane switching with awareness of Vim splits.
    # See: https://github.com/christoomey/vim-tmux-navigator
    is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|[ln]?vim?x?)(diff)?$'"
    bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
    bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
    bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
    bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
    if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
    if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

    bind-key -T copy-mode-vi 'C-h' select-pane -L
    bind-key -T copy-mode-vi 'C-j' select-pane -D
    bind-key -T copy-mode-vi 'C-k' select-pane -U
    bind-key -T copy-mode-vi 'C-l' select-pane -R
    bind-key -T copy-mode-vi 'C-\' select-pane -l
    bind-key -T copy-mode-vi 'v' send -X begin-selection
    bind-key -T copy-mode-vi 'y' send -X copy-selection
  '';
  historyLimit = 1000000;
  keyMode = "vi";
  mouse = true;
  newSession = true;
  plugins = with pkgs; [
    tmuxPlugins.vim-tmux-navigator
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = ''
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-dir '~/.local/state/tmux/resurrect'
      '';
    }
    {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
    }
    {
      plugin = tmuxPlugins.mkTmuxPlugin {
        pluginName = "themepack";
        version = "master";
        src = pkgs.fetchFromGitHub {
          owner = "jimeh";
          repo = "tmux-themepack";
          rev = "7c59902f64dcd7ea356e891274b21144d1ea5948";
          sha256 = "sha256-c5EGBrKcrqHWTKpCEhxYfxPeERFrbTuDfcQhsUAbic4=";
        };
      };
      extraConfig = ''
        set -g @themepack 'powerline/double/cyan'
        set -goq @themepack-status-right-area-right-format "#h"
      '';
    }
  ];
  prefix = "C-a";
  shell = "/etc/profiles/per-user/fdrake/bin/fish";
  shortcut = "a";
  terminal = "screen-256color";
}
