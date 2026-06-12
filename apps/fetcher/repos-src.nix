####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-nvim-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "2a132953b944561d45b52e4541ebfff71934a742";
    hash = "sha256-4kvDnzLYFDDqcnpPWuNv3uXKDOHZjFLFTYtRGmP7rsc=";
  };
  container-digest-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "container-digest";
    rev = "8f71e0622f7f502ae0ba1068dc093e7e1391dd58";
    hash = "sha256-c+HgcGewHeIUo8I8yQI36QpKH6rWvSmMTHKiCA2l1Xk=";
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
    rev = "0069dbbe06cc05482bfb13063b4b4eac26318992";
    hash = "sha256-H7HgYT+okuVXo2SinrSs+hxAKCn4Q4su7oMbebKd/7s=";
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
    rev = "83174b07de60078be79985ef6123d903329622b8";
    hash = "sha256-Dhx5+XRxJvlhdnFyimNxFyFiASrGU4ZwyefsDwtKnSg=";
  };
  gitea-mcp-src = pkgs.fetchgit {
    url = "https://gitea.com/fdrake/gitea-mcp";
    tag = "v0.3.0";
    hash = "sha256-hJQ0ryEcPg/WOi54RLZswhWZOjkbllZWOsYyOhe+4AA=";
  };
  vicinae-src = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "dc18d101a1d1da480f9d56bcbf4c19f9f657b89d";
    hash = "sha256-0KLvaBv5yz4Bm/Nu/4S4btUOZB+oA2zWv39OjtySWUA=";
  };
  spotifatius-src = pkgs.fetchFromGitHub {
    owner = "AndreasBackx";
    repo = "spotifatius";
    rev = "6eceb8e992ba2d1d89d370961a18a1fdeae729fa";
    hash = "sha256-esQiz9nduOm7nAUIq/Y5dMMxpKo2m19lEbZl6iRcxpo=";
  };
  scanimage-web-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "scanimage-web";
    rev = "030c6a985cb22eca47a5fed7f0c67f9786afb284";
    hash = "sha256-JuGiHHvjz5EC+BUnthjIA9Sgef39fo7QtWjf4kB5U9g=";
  };
}
