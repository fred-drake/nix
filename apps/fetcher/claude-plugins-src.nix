####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/0412be76f50ab4f4f8abff3753efa9269fbbca5b.tar.gz";
    sha256 = "1ni37vxzhv7zkqmrrjiv4zfl84q9pq5ikwdsal0fpl9s8b1bpa4q";
  };
  "cc-marketplace-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "798628ffea78a712f0bd51a372fa58baaa201c06";
    hash = "sha256-4Lp4oq2VsOlexC4fYF01ZHPCIcNmkMnZweavnat7j3A=";
  };
  "cc-skills-golang-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "d68d80aec298e1b74b37c2a472c002b5217248b3";
    hash = "sha256-Kc3OXcnaFjo+4rcH7AiBg0tJcVqXAnQvJv+pfuHETMw=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "22f0b463e7a5e579904dd6211a520321035526f7";
    hash = "sha256-rP5YsyGuPd9YSW/Fj3aukrq1bLuV+nwwQMK4JaZQgkI=";
  };
  "karpathy-skills-src" = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  "agent-rules-skill-src" = pkgs.fetchFromGitHub {
    owner = "netresearch";
    repo = "agent-rules-skill";
    rev = "6553bc5c9b8f9d215b1e13f90a88fb4b6a0cb00f";
    hash = "sha256-w/LYE5leQX+lyUpo/GuWI+Unt/c4YtvwIble9QtPG2Y=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "2c5958ecac7cee2b583967a2c4981d0f4a75c579";
    hash = "sha256-dRCZrNarCCJFuvATgfW6qmwwVS5HGFXNVGOhbVZd7LA=";
  };
  "apollo-skills-src" = pkgs.fetchFromGitHub {
    owner = "apollographql";
    repo = "skills";
    rev = "9dda1397730370aeb8df4ff8f2015c34c86b5003";
    hash = "sha256-TSGowC+gRHxPqhSvT1ySu+/yZPp4R2rbYWZ3V4IadcU=";
  };
  "vercel-agent-skills-src" = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62";
    hash = "sha256-uujS8sGulF6STR4adqYCHBxPY9pHddXfFfX6UqAG24c=";
  };
  "trailofbits-skills-src" = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "e4dd0bb5b15535f7c5a0834187dffba6ac37e4ff";
    hash = "sha256-Ayq9NufLWIjNTFf/13BwlkcwrYzMpzI7XVuq3Tsgeyk=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "1af7e69a2a613437d46095924057970a6a7df40d";
    hash = "sha256-4Au01HgH3CbBvXihKaI3hUJOwIaJ0vh15TBSvGw/cAs=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "f07e2cf11ce9a4d876d881bf94bef10d29b95c2e";
    hash = "sha256-b6p07sBDzaqHCeYOilskkiXH3uOjgAB82bhsMDzv2tY=";
  };
  "variate-src" = pkgs.fetchFromGitHub {
    owner = "Nutlope";
    repo = "variate";
    rev = "3a82377d2e13160d879de18b40b323287f1636d9";
    hash = "sha256-aHRi2IUo9nfGSIrQKHAIAYBU6eo8VhOhMeWRXtdUVwc=";
  };
  "slavingia-skills-src" = pkgs.fetchFromGitHub {
    owner = "slavingia";
    repo = "skills";
    rev = "eb9f57fba03ddb0382ed3bfe6654d3d7df128c70";
    hash = "sha256-TwuhBL6EdM5+l0V/XK1xJ0bduyb15Fd5qe3O/ceEVdg=";
  };
  "matt-pocock-skills-src" = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "4ae2317ddb22b046e26455e4f9c9b3aaaf62212d";
    hash = "sha256-3vhd77xfZjKUYJsIwPFevIZPUAzUgZXr0RYj5NQrBwk=";
  };
}
