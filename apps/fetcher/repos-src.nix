####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-nvim-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "6b62f73a6bf317531d15a7ae1b724e85485d8148";
    hash = "sha256-MxFONokzF2TdsQtOagh/in2xlbZLk6IhjWonExB/rtY=";
  };
  container-digest-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "container-digest";
    rev = "bcc31e383623403b0a33dd2e21751ddd1f262c28";
    hash = "sha256-zBQDSr3bXuP9U3YIu9VQkYqfBP5p/5b+uLeai6a82Yk=";
  };
  npm-refresh-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "npm-refresh";
    rev = "58f0fb1a3a9ea87f8780f4834f78396d4d9ba1b6";
    hash = "sha256-svg5/+mqBOvZxLLHBvXKmANpuBN+simUIY7QX0Yscz4=";
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
  gitea-mcp-src = pkgs.fetchFromGitea {
    domain = "gitea.com";
    owner = "fdrake";
    repo = "gitea-mcp";
    rev = "comment-index";
    hash = "sha256-8L2VQcU2mhRimWr2qGDRw7f/yYO5V+1kswuLlCqhpio=";
  };
  kuma-waybar-src = pkgs.fetchFromGitHub {
    owner = "WebTender";
    repo = "kuma-waybar";
    rev = "8af4832831f7c81f8f3f81bf0ba9f2e734c1f860";
    hash = "sha256-NGofCO+7WsJtCvlTzj6JCjukcRT0IAJwinbk3shPKFE=";
  };
  vicinae-src = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "789f5dc7d90ccd291e85cd3f635bab70d0d3a370";
    hash = "sha256-9MCHEUzOMrER+4P0PFHdbesuuVIvKQHtCOZ8g5QMOqs=";
  };
  tdd-guard-src = pkgs.fetchFromGitHub {
    owner = "nizos";
    repo = "tdd-guard";
    rev = "5e0c9a5e37c71f7bc7fdfc3b85b3365792f5d185";
    hash = "sha256-tqyuTWuZhBEUiAMh6O/YOWGfdnqzL4Do7oFJRviM7Ow=";
  };
}
