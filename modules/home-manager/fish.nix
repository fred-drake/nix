{ pkgs, ... }: {
  enable = true;
  interactiveShellInit = ''
    # Kill stock greeting
    set fish_greeting

    # Cursor styles
    set -gx fish_vi_force_cursor 1
    set -gx fish_cursor_default block
    set -gx fish_cursor_insert line blink
    set -gx fish_cursor_visual block
    set -gx fish_cursor_replace_one underscore
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
    {
      name = "tide";
      src = pkgs.fetchFromGitHub {
        owner = "IlanCosman";
        repo = "tide";
        rev = "44c521ab292f0eb659a9e2e1b6f83f5f0595fcbd";
        sha256 = "sha256-85iU1QzcZmZYGhK30/ZaKwJNLTsx+j3w6St8bFiQWxc=";
      };
    }
  ];
  shellAbbrs = {
    "lg" = "lazygit";
    "cm" = "chezmoi";
  };
  shellAliases = {
    "lart" = "eza -lar --sort=modified";
    "las" = "eza -la --sort=size";
    "lat" = "eza -lar --sort=size";
    "update" = "chezmoi apply && darwin-rebuild switch --flake ~/.config/nix/flake.nix";
  };
}
