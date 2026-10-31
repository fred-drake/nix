####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/a7ba5b93db0c7c8d17f3f1d25853adca79598a1a.tar.gz";
    sha256 = "0w1aq66s5x1r2kc8rra7xkz18g7wxjvhv79zfzxz44ja5d297jqb";
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
    rev = "246b6c4c1ab3077dee114beb9ade3bb0527dfebc";
    hash = "sha256-RqhTRSPCDtQkcxi5vwwNh1k8yIRozQIWZgM4kTuqBu4=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "2ce8aa15d05bd57213e6f746f953aafb7ded7a8b";
    hash = "sha256-9+69YEdjdaDu5sWTyAbufSVcZgGD7h6wAq4nUVY2syE=";
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
    rev = "aa0ff50699a60d4a02de70be3af83182b766fe33";
    hash = "sha256-AVJXZsUuXaHLEFLNy9txr8kuB0OszT6lc5H6vEW94Y0=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "ca45fc496a3436251f191354091d557da31c15b5";
    hash = "sha256-MkCOANBAqCc1WmNf7S8PsyAphGJAIzEXGyCm8RrCR9M=";
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
    rev = "2be6433b39e009cd2b6fd3be1895f6b1faa5af9a";
    hash = "sha256-vQiXAEv3+VsLweirfFaN1nD/PWuiDOlT5LeSLwIa304=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "30d4553ecd46fbc5212fd0ff006ae43af522158b";
    hash = "sha256-JMp9uPj4hfKGhAzD6TMrPt2knEp3AoxUW1SVzTdWF28=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "88c79f6528a9347420e57ceb1fff9a60de651768";
    hash = "sha256-xaBcBdjdn3siGvXk43bPDu6pGxGw5vwBikwOKTCRUAY=";
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
    rev = "a496f5513d4a4cf889bc48e189e579f4b0bdf6aa";
    hash = "sha256-XpP8D7V2seR0sJ9bErscXgVLY2+6QiaA8TR/l8v2gx0=";
  };
}
