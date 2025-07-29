####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-nvim-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "0eb9289ab39c91caf8b3ed0e3a17764809d69558";
    hash = "sha256-1ZZ2rtkOKAQdgMfgakNqi8NZzO2yPdvMFCs7mjS1ckI=";
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
    hash = "sha256-4vZQWAJ+0w64UZ20zFE24BITtU/5wz2eBSzONtyElcQ=";
  };
}
