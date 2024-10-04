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

      direnv hook fish | source

      oh-my-posh init fish --config ~/.config/oh-my-posh/config.toml | source
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
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "85f863f20f24faf675827fb00f3a4e15c7838d76";
          sha256 = "sha256-+FUBM7CodtZrYKqU542fQD+ZDGrd2438trKM0tIESs0=";
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
    ];
  };
}
