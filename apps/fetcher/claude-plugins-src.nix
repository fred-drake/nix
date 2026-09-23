####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/db467cc56673fc963ca418b4165c688dfbe77007.tar.gz";
    sha256 = "0vaa2ghp9kagm6am1ra79njx6lgj2pmx882xiz7hraa9gw1yybll";
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
    rev = "19a0626ae8565d27a7b7bdf59d8d99d94d7e284c";
    hash = "sha256-owdNtWmTwxzzrmS0XwU/8GKbJmDKl0uqi9VpiBhemps=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "5bf4e78011075bcfc0dc295f0724994cd123ee71";
    hash = "sha256-rgeJhjQyABYlhlyFRmgyhbZmmmIPPNkch4CXyTkGEyM=";
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
    rev = "7e1a602f6c735d076afa0bf09c4b8e09bf1b8e3b";
    hash = "sha256-Pa4QVmlFxi8acU9lOAbmdmIrZ70U3ElR3+MhMDupr/U=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "34040c9c568585f6929bedeaad110ad08f079624";
    hash = "sha256-tI4bTTBfI1ylltklGyiyA7pLoKXEWtrT6lrmwrpLbCw=";
  };
  "apollo-skills-src" = pkgs.fetchFromGitHub {
    owner = "apollographql";
    repo = "skills";
    rev = "c288eb80629dd2309eed81f23d693f66a452d043";
    hash = "sha256-YSmu2te3xwvQzshGhKNzKgldUg0lBMgHwGiNxFeDAv8=";
  };
  "vercel-agent-skills-src" = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "063bee94c3f4df8453406c830b0a7df0f2860278";
    hash = "sha256-tTSJf53OQltUfxTH4hdqcnw5ywCjCZP8/JqQ593cyB8=";
  };
  "trailofbits-skills-src" = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "32e34f8173796e3566a51aee877dc96bc5191f64";
    hash = "sha256-ujaD5H89JdhYLeqJuSPGsFTYttYDbwLoHBD422w/I1k=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "9682e994989f951c75912fbc49aa10332a512685";
    hash = "sha256-BRdhHYm2RW7EPx1ZbJgDu075REuxsQXQXPwJooNpGRM=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "5b2c0007766c6a1cf1d53fd8fc73e979e0821022";
    hash = "sha256-x2dcZrwUMaGK4wHNQtE2TvPH5mBR474mW0Y5fQb19dw=";
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
  "herdr-src" = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "cd8306d7f35d6329d543944a0257b6bc4b297c8b";
    hash = "sha256-OyvLHxxPBaN/CNhSJVKY0Eosw96zjq/8Ji3FUmRrJGk=";
  };
}
