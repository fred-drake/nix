####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-nvim-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "c293eb56db880a0539bf9d85b4a27816960b863e";
    hash = "sha256-xKu05IgOpgtt2W+WqXuTUjX66ffDrU8BDi8z7M6M1q4=";
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
  gitea-mcp-src = pkgs.fetchFromGitea {
    domain = "gitea.com";
    owner = "fdrake";
    repo = "gitea-mcp";
    tag = "v0.3.0";
    hash = "sha256-hJQ0ryEcPg/WOi54RLZswhWZOjkbllZWOsYyOhe+4AA=";
  };
  vicinae-src = pkgs.fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "8dea928bfea1da8c05527a3f55fe2e159ebf1c9e";
    hash = "sha256-o9jx6JIzonYliAkAzY8Zpqje3Ve9lyB+N4JujfKVLPc=";
  };
  spotifatius-src = pkgs.fetchFromGitHub {
    owner = "AndreasBackx";
    repo = "spotifatius";
    rev = "6eceb8e992ba2d1d89d370961a18a1fdeae729fa";
    hash = "sha256-esQiz9nduOm7nAUIq/Y5dMMxpKo2m19lEbZl6iRcxpo=";
  };
  gws-skills-src = pkgs.fetchFromGitHub {
    owner = "googleworkspace";
    repo = "cli";
    rev = "a3768d0e82ad83cca2da97724e46bea4ff0e6dbd";
    hash = "sha256-YyNIHbyZrLlXYtWxZY8Um19MsnLharmS+nWGWO89fsA=";
  };
  scanimage-web-src = pkgs.fetchFromGitHub {
    owner = "fred-drake";
    repo = "scanimage-web";
    rev = "030c6a985cb22eca47a5fed7f0c67f9786afb284";
    hash = "sha256-JuGiHHvjz5EC+BUnthjIA9Sgef39fo7QtWjf4kB5U9g=";
  };
}
