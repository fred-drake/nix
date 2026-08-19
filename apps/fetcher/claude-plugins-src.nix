####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/ed279d8005254045c2e9806ba5c1d7c5b9e2f8c6.tar.gz";
    sha256 = "0laa6nm9bmcdb4igrbdmykj99z2jxcdh7lkf3r181wpkp7q0pqpm";
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
    rev = "ebf4f0a2a686e4a55e4489b40fbe4165194c49e4";
    hash = "sha256-GDwPHuIM8RyAAFf3TCyneZe6BUetBDvYR4SxSC2OVL8=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "0a64e398ec6bb34a494f0c347e8ccae53a862f8e";
    hash = "sha256-0ZtHTJVHeW8jIprKgCo/yU2ZI2cZxUqD3Riet3UWdt8=";
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
    rev = "07bce8a2c8ccc56c5b44b7067a04b8bf46128f05";
    hash = "sha256-YXXBCTNxcTt+6oH/8bgR9n/iFFD7ND3VjtZTlxqTiYY=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "21320596cf9008cf6ccaa6bf1a2b9f71c8f191c3";
    hash = "sha256-m7Qce/fgINqSh778xICLVMCzwkqY4KLxPMubrgKRqnU=";
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
    rev = "5203a5dc0f39a082938ea0f9836d6257ea7e155f";
    hash = "sha256-LrqZGXng9hTBKbaI8HcQOAF5zSEo+gOFJJ6strLrcq4=";
  };
}
