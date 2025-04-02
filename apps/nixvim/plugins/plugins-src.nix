####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  outline-src = pkgs.fetchFromGitHub {
    owner = "hedyhli";
    repo = "outline.nvim";
    rev = "ae473fb51b7b6086de0876328c81a63f9c3ecfef";
    hash = "sha256-XiPWp5ohjmTErMckcX25dstiVmUQbXNjJ6ONiib0qok=";
  };
  augment-src = pkgs.fetchFromGitHub {
    owner = "augmentcode";
    repo = "augment.vim";
    rev = "97418c9dfc1918fa9bdd23863ea3d2e49130727f";
    hash = "sha256-ekexQ2tI/GxEbNHhxF0fj0vwIH3+H0joSayL9vmlBOs=";
  };
}
