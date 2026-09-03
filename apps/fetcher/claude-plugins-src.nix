####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/0120fb83da5d7cdaa52dd11979690f2dc5f76052.tar.gz";
    sha256 = "0g1sladw815sgw909a1rb4xqxlm2p9dbzzlgbcc59j824r1wsd41";
  };
  "cc-marketplace-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "cf33ec47ef0b3294483222793f686e688d865015";
    hash = "sha256-xIvK8b2CHxlT5IUsW9+AdF3h9dtZid/hHSFAcJwRzDI=";
  };
  "cc-skills-golang-src" = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "bac46b0bed2677f840837e16be2c790341bda2df";
    hash = "sha256-En3q5nFnATE3cSYFuGZoVDedFvV/ewRxRXTziQXfqsM=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "b36e0829c6d0140e93cfef2ca599b1b07d4a7797";
    hash = "sha256-EsGNO0dULWf5Bx6bGrCv2kI2Z8aKH0kRvGiuN23wChQ=";
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
    rev = "47a8510fc0e78a5852b8a10f980677e0ea2341ba";
    hash = "sha256-eNPMdnQEmp2Djhwl5vVIISSmFd9gamSQId+JNueOo9Q=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "41bbe19d1a1a7eaab5e7bb9050a417e5c6cffc8f";
    hash = "sha256-sjgPv9tZZVTXPxZWaCOc7JwFceNn3C1ghy8mSHqgqB8=";
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
    rev = "d3323cefbcf645678b8dc481de204b02ad3d02dc";
    hash = "sha256-gkNXbN3CwrQ0tRmD9JTDeb+uPlSkGUpUi8Pan4EAWlw=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "54e9b19a612897171e0b3b242e01c2badba4a272";
    hash = "sha256-9kEMWaPLiPtp9GHsI+hxIgXZpDRfA9KvD3No4At0pX0=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "5cd4a7eae3a9a7b5d2aceb0613f7d1f7c4b65968";
    hash = "sha256-B210znhOr+gxKx+lpLkQq9a4S2F1qwYqAUyHXT7vbmM=";
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
    rev = "b07ba9ced8b57099f038bc633ed1c9a5f5b3a1ed";
    hash = "sha256-PZklH2jf24HGHrczgc0Tlvnkh0PJjqSxNRdEDN2xCXE=";
  };
}
