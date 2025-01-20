{pkgs, ...}: {
  # Tmux multiplexer configuration
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
      tmuxPlugins.tmux-fzf
    ];
    extraConfig = ''
      # remap prefix from 'C-b' to 'C-a'
      unbind C-b
      set-option -g prefix C-a
      bind-key C-a send-prefix

      # set mouse mode
      set -g mouse on

      # split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # reorder windows if one closes
      set-option -g renumber-windows on

      # reload config file (change file location to your the tmux.conf you want to use)
      bind r source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded!"

      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
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

      # Move window order
      bind -r "<" swap-window -d -t -1
      bind -r ">" swap-window -d -t +1

      # Resize panes
      bind -r C-j resize-pane -D 5
      bind -r C-k resize-pane -U 5
      bind -r C-h resize-pane -L 10
      bind -r C-l resize-pane -R 10

      # base 1 indexing for windows and panes
      set-option -g base-index 1
      setw -g pane-base-index 1

      # Create new window with same directory as current pane
      bind c new-window -c "#{pane_current_path}"

      # DESIGN TWEAKS

      # don't do anything when a 'bell' rings
      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      # clock mode
      setw -g clock-mode-colour yellow

      # copy mode
      setw -g mode-style 'fg=black bg=red bold'

      # panes
      set -g pane-border-style 'fg=gray'
      set -g pane-active-border-style 'fg=green'
      set -g pane-border-lines "single"


      # statusbar
      set -g status-position bottom
      set -g status-justify left
      set -g status-style 'fg=red'

      set -g status-left ""
      set -g status-right ""
      set -g status-left-length 10

      setw -g window-status-current-style 'fg=white bg=#003399'
      setw -g window-status-current-format ' #I #W #F '

      setw -g window-status-style 'fg=gray bg=black'
      setw -g window-status-format ' #I #[fg=white]#W #[fg=yellow]#F '

      setw -g window-status-bell-style 'fg=yellow bg=red bold'

      # messages
      set -g message-style 'fg=black bg=red bold'
    '';
  };
}
