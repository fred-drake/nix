{pkgs, ...}: {
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

      # Add LLM API keys to environment
      source ~/.llm_api_keys.fish

      direnv hook fish | source

      # oh-my-posh init fish --config ~/.config/oh-my-posh/config.toml | source

      zoxide init fish | source
    '';
    plugins = [
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "autopair.fish";
          rev = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
          sha256 = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
        };
      }
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
          sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
          sha256 = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
      {
        name = "puffer-fish";
        src = pkgs.fetchFromGitHub {
          owner = "nickeb96";
          repo = "puffer-fish";
          rev = "12d062eae0ad24f4ec20593be845ac30cd4b5923";
          sha256 = "sha256-2niYj0NLfmVIQguuGTA7RrPIcorJEPkxhH6Dhcy+6Bk=";
        };
      }
    ];

    shellAbbrs = {
      cm = "chezmoi";
      df = "duf";
      k = "kubectl";
      mc = "ranger";
      t = "tmuxinator";
      telnet = "nc -zv";
      la = "eza -a";
      ll = "eza -l";
      lla = "eza -la";
      lat = "eza -a --sort newest";
      llat = "eza -la --sort newest";
      lart = "eza -ar --sort newest";
      llart = "eza -lar --sort newest";
    };
  };
}
