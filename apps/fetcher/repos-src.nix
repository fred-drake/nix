####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-nvim-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "321f89ef79f168a78685f70d70c52d0e7b563abb";
    hash = "sha256-fbNVSAOzdmmfTV4CkssTpw54IZbCCLUOguO/huEB6eU=";
  };
  augment-nvim-src = pkgs.fetchFromGitHub {
    owner = "augmentcode";
    repo = "augment.vim";
    rev = "97418c9dfc1918fa9bdd23863ea3d2e49130727f";
    hash = "sha256-ekexQ2tI/GxEbNHhxF0fj0vwIH3+H0joSayL9vmlBOs=";
  };
  container-digest-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "container-digest";
    rev = "47ea5137a2f7a2eff863d6d336f613d70edddfbe";
    hash = "sha256-iGNGpO/6MHlDnhDdttJRxbRINmwmEi7p5AnX5PqHhDc=";
  };
  autopair-fish-src = pkgs.fetchFromGitHub {
    owner = "jorgebucaran";
    repo = "autopair.fish";
    rev = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
    hash = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
  };
  fzf-fish-src = pkgs.fetchFromGitHub {
    owner = "PatrickF1";
    repo = "fzf.fish";
    rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
    hash = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
  };
  fish-abbreviation-tips-src = pkgs.fetchFromGitHub {
    owner = "gazorby";
    repo = "fish-abbreviation-tips";
    rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
    hash = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
  };
  puffer-fish-src = pkgs.fetchFromGitHub {
    owner = "nickeb96";
    repo = "puffer-fish";
    rev = "12d062eae0ad24f4ec20593be845ac30cd4b5923";
    hash = "sha256-2niYj0NLfmVIQguuGTA7RrPIcorJEPkxhH6Dhcy+6Bk=";
  };
  nix4vscode-src = pkgs.fetchFromGitHub {
    owner = "nix-community";
    repo = "nix4vscode";
    rev = "eadb4fd1878b8a24132f6073de244c2684ecc901";
    hash = "sha256-bra6KP3L+yyWyWEBPy6RPvuOGws85DRyojXvOnYrVy0=";
  };
}
