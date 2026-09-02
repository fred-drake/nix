####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/e18ff5086423bd9c21902ce3100dc4ecc84a668a.tar.gz";
    sha256 = "11bdfd3g2w03nsx4jynxrp98hyc877hca044nkqq73r6z9h8ikm0";
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
    rev = "ec8c349e295a6c1057743841e7b0f6d06adc1c0b";
    hash = "sha256-BaA27PJcdoDJ5LA/wqIdOwBWbTJX9w7m8AbaC50hzQQ=";
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
    rev = "06acfe610ef996bea0933585f7e6fa1dc1b639bf";
    hash = "sha256-4RpGDOdrOgWI8OQ2XZdUZpcLAKiEoYh2stmmHHqP5qM=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "53048666b05b4799081517d00e09e0a2dd688678";
    hash = "sha256-xaxkXFpzH4s2OIOcZqPy+HzfRAy2HbKpagjMhY+uinA=";
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
    rev = "14e5a1070020c5d101e8362756f3201fb677b467";
    hash = "sha256-Qs1LfZLfFgB+0tKPIS4kRa8TYmGZ7bkRX1iCN/4xFes=";
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
    rev = "d4ff28a9c8d56c06809860bf2800d4f5224b52db";
    hash = "sha256-MXsX+1y3qf5dWCuc9mafKLgRNkb7LjwEdr2tKznw4K8=";
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
    rev = "cc88b3b8e5bb9f7d9f23ed6ae85a52fd7b5b9ed6";
    hash = "sha256-B5Tlex5ueCRyNTGA2m45FkaRlm4H2ZoylIKz9YxdGRM=";
  };
}
