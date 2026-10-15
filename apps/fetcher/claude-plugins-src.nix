####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/c2bdb427efe8673f190ae862c273cfa368d2390f.tar.gz";
    sha256 = "02sglzhmfwfhj5nvw7igxmx58ai6cj4kc39jwxjhyiyhcnp3nv2r";
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
    rev = "8e899e20ff0cd4dc524af3993e4c62d8ee8c5717";
    hash = "sha256-GYayraudW1jRetezgPZe3BUOSAc7N94HH/hlAGNXjzc=";
  };
  "superpowers-src" = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "bb92a77741419a4ab5f06e711a283343f1ada0c3";
    hash = "sha256-UCVI+T7j1Xh1LDkrvnJduis7eHFqrizCyGTWAGW5d6U=";
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
    rev = "1fb399373792e7e0a9966cdfb201ae192fe95347";
    hash = "sha256-Ml+n67oqBv1VQXE8p5mHy7qaBvowvarhBBX/+mtkwII=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "dbd4588f9e1033efb41dad4bef2f7947c8993d44";
    hash = "sha256-+UIqBnzyeIOvJSKYaDaE3GYPEpLw7qQqyUw5S971AfU=";
  };
  "apollo-skills-src" = pkgs.fetchFromGitHub {
    owner = "apollographql";
    repo = "skills";
    rev = "aafc8944365a766d48cc519ce8b8575f93f953a4";
    hash = "sha256-UzLzbqQXU50aD3Bx6rARrn5EuvKne+I0f+/teDMYVOs=";
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
    rev = "e1f86a390d4caf28bf1c377a7d86707b2898669c";
    hash = "sha256-WkNajKsDW4F1GuMMqCh9YwimGi8SgHaLk0jt2q+RbGI=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "7ba4dcf8ebe1626b00baa41e1f2478113719b60b";
    hash = "sha256-9bcjFgd02/+BXCbvvEOvd0C+WEbtlFYraH6TfqDbKCI=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "55ff469422c3592dac45bcad08dfb40221981c02";
    hash = "sha256-lTWD1IXOEgtFRg4UPInEbegAsPF1PDY+yfn6uj2NLmw=";
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
    rev = "916fcf8de029c6cac965b50f3cdb9687cd7d1537";
    hash = "sha256-qi4htt98YMOPi/UEkr8tjOHJlsyY23NCSK6qTncQtaE=";
  };
}
