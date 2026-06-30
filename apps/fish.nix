{
  pkgs,
  config,
  ...
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
in {
  programs.fish = {
    enable = true;
    shellInit = ''
      # Ensure ~/.local/bin is in PATH for all shell contexts (idempotent)
      fish_add_path $HOME/.local/bin
    '';
    interactiveShellInit = ''
      # Kill stock greeting
      set fish_greeting

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

      # Build dev windows. Now backed by cmux — `windev` is an alias for `cws`
      # so existing muscle-memory / completions keep working.
      function windev
        cws $argv
      end

      # Create (and focus) a cmux workspace for a project.
      #   cws <name> [dir] [color]
      # Looks up dir + color from the windev registry (~/.config/windev/config.json)
      # by <name>; explicit [dir]/[color] args override. Unknown names just open
      # in the current directory with no color.
      function cws
        if not command -v cmux >/dev/null 2>&1
          echo "cws: cmux not found" >&2
          return 1
        end
        set -l name $argv[1]
        if test -z "$name"
          echo "usage: cws <name> [dir] [color]" >&2
          return 1
        end
        set -l config_file "$HOME/.config/windev/config.json"

        # Resolve directory: explicit arg > registry > pwd
        set -l devdir
        if test -n "$argv[2]"
          set devdir "$argv[2]"
        else if test -f "$config_file"
          set devdir (jq -r --arg name "$name" '.[] | select(.name == $name) | .dir' "$config_file" 2>/dev/null)
        end
        if test -z "$devdir"; or test "$devdir" = "."
          set devdir (pwd)
        end

        # Resolve color: explicit arg > registry > none
        set -l color
        if test -n "$argv[3]"
          set color "$argv[3]"
        else if test -f "$config_file"
          set color (jq -r --arg name "$name" '.[] | select(.name == $name) | .color // empty' "$config_file" 2>/dev/null)
        end

        set -l ws (cmux workspace create --name "$name" --cwd "$devdir" --focus true --id-format uuids | string replace 'OK ' "")
        if test -n "$color"
          cmux workspace-action --action set-color --color "$color" --workspace "$ws"
        end
      end

      # Add LLM API keys to environment
      # source ~/.llm_api_keys.fish

      direnv hook fish | source

      # oh-my-posh init fish --config ~/.config/oh-my-posh/config.toml | source

      zoxide init fish | source

      # television smart autocomplete and shell history
      tv init fish | source
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
      hermes = "ssh orgrimmar podman exec -it hermes hermes";
      cld = "claude --add-dir ~/Screenshots";
      cldc = "claude --add-dir ~/Screenshots --continue --dangerously-skip-permissions";
      cld-go = "claude --add-dir ~/Screenshots --plugin-dir ~/plugins/cc-skills-golang --plugin-dir ~/plugins/superpowers";
      pi-go = "pi --skill ~/plugins/cc-skills-golang/skills";
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
      fish-reload = "exec fish";
      model-ornith-1-0-35b-8bit = "uvx --from mlx-vlm mlx_vlm.server --model mlx-community/Ornith-1.0-35B-8bit --port 8080";
    };
  };
}
