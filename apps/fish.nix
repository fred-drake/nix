{
  pkgs,
  config,
  ...
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
in {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Kill stock greeting
      set fish_greeting

      set -gx fish_key_bindings fish_vi_key_bindings

      # Cursor styles
      set -gx fish_vi_force_cursor 1
      set -gx fish_cursor_default block
      set -gx fish_cursor_insert line blink
      set -gx fish_cursor_visual block
      set -gx fish_cursor_replace_one underscore

      # fzf options
      set fzf_diff_highlighter delta --paging=never --width=20
      set fzf_preview_dir_cmd eza --all --color=always

      # Render vi mode
      function render_vi_prompt
        set_color $argv[1]
        echo -n ' '
        set_color --bold $argv[2]
        set_color --background $argv[1]
        echo $argv[3]
        set_color --background normal
        set_color $argv[1]
        echo -n ''
      end
      function fish_mode_prompt
        switch $fish_bind_mode
          case default
            render_vi_prompt red white "NORMAL"
          case insert
            render_vi_prompt 799468 white "INSERT"
          case replace_one
            render_vi_prompt green white "REPLACE"
          case visual
            render_vi_prompt brmagenta white "VISUAL"
          case '*'
            render_vi_prompt red white "??????"
        end
        set_color normal
      end

      function y
       set tmp (mktemp -t "yazi-cwd.XXXXXX")
       yazi $argv --cwd-file="$tmp"
       if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
       end
       rm -f -- "$tmp"
      end

      # Build dev windows
      function windev
        set config_file "$HOME/.config/windev/config.json"
        set domain "${config.soft-secrets.networking.domain}"

        # If argv[2] is provided, use it as the directory
        if test -n "$argv[2]"
          set devdir "$argv[2]"
        else if test -f "$config_file"
          # Read configuration from JSON file
          set devdir (jq -r --arg name "$argv[1]" '.[] | select(.name == $name) | .dir' "$config_file" 2>/dev/null)

          # If no match found in config, check for special placeholders
          if test -z "$devdir"
            set devdir (pwd)
          else
            # Replace $HOME placeholder if present
            set devdir (echo "$devdir" | sed "s|\$HOME|$HOME|g")
            # Replace $domain placeholder if present
            set devdir (echo "$devdir" | sed "s|\$domain|$domain|g")
          end
        else
          # If config file doesn't exist, use current directory
          set devdir (pwd)
        end

        # Debug output
        # echo "windev: argv[1]='$argv[1]', devdir='$devdir'"

        tmux new-window -n "$argv[1]" -c "$devdir"
        tmux split-window -h -c "$devdir"
        tmux select-pane -t 1
        tmux split-window -v -c "$devdir"
        tmux select-pane -t 3
        tmux kill-pane -t 1
        tmux select-pane -t 1
        tmux split-pane -v -c "$devdir"
        tmux select-pane -t 3
      end

      # Add LLM API keys to environment
      # source ~/.llm_api_keys.fish

      direnv hook fish | source

      # oh-my-posh init fish --config ~/.config/oh-my-posh/config.toml | source

      zoxide init fish | source
    '';
    plugins = [
      {
        name = "autopair.fish";
        src = repos-src.autopair-fish-src;
      }
      {
        name = "fzf.fish";
        src = repos-src.fzf-fish-src;
      }
      {
        name = "fish-abbreviation-tips";
        src = repos-src.fish-abbreviation-tips-src;
      }
      {
        name = "puffer-fish";
        src = repos-src.puffer-fish-src;
      }
    ];

    shellAbbrs = {
      cm = "chezmoi";
      cld = "claude --mcp-config ~/mcp-config.json --dangerously-skip-permissions --add-dir ~/Screenshots";
      df = "duf";
      k = "kubectl";
      telnet = "nc -zv";
      la = "eza -a";
      ll = "eza -l";
      lla = "eza -la";
      lat = "eza -a --sort newest";
      llat = "eza -la --sort newest";
      lart = "eza -ar --sort newest";
      llart = "eza -lar --sort newest";
      known-hosts-clear = "ssh-keygen -R";
    };
  };
}
