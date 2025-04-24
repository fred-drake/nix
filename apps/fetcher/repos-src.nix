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
}
