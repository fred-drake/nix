####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/0bc1c2e378c6d9d04c2914ce61c646832cd4e337.tar.gz";
    sha256 = "091hlrsggzmdv6r7fr0zd11ncmv1lsjjpy32xmbmcg9qqlyb6abw";
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
    rev = "30cdf15cde8db8730c42a2918d7cdb4505f5ff54";
    hash = "sha256-IQ2v1V1JfZrdQXcS2Bv17+f1bbTaplyBIMD8angY/t8=";
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
    rev = "d49080028a5b782281723305829fa2eeb4dc4852";
    hash = "sha256-mikMHMF4eMbeVxN4TG/+JxyWQP19zeNVELOYpMb2tA4=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "f6656c1256d5a8adfa37db9110046ef20bac644c";
    hash = "sha256-5/0f5AnGWX3oM+M9Xm/zSmooz11+S1YRdFPmAX+DXi0=";
  };
  "vercel-agent-skills-src" = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "b8caa260a420a73042e35521de4b5c8baf6446cc";
    hash = "sha256-McF7KAswDpkX0FtjFX7vOva8YwQTFwxewjYhueQgtIA=";
  };
  "trailofbits-skills-src" = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "4db88ee79db0a68bbe049fe827e272ee2bc19510";
    hash = "sha256-KXhkSvBXH9axfJb6MlII7GVXSePK+91aRvrxi2bB/pE=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "9f0faa5056c3167d0fc0b7e9575d35284dce98c8";
    hash = "sha256-zIvhiYUS85BZJh0K+dJhLPcbr3iA/Pwk8JKLk1E9YPk=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "7868cb9251fad80a73d26e488a5ad5f6c4a9f335";
    hash = "sha256-NfHll8eEj5QZt0ubURhJdIhms1RuMAoAKHXOsss3U4s=";
  };
  "herdr-src" = pkgs.fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "51b7064ef0a02642393bab1d2eea0f4dbd8414d2";
    hash = "sha256-ALhahxbdgnN8rMvlKmgB5py0etICwyYY75Uz0jLIpM4=";
  };
}
