####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  "claude-plugins-official-src" = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/5cec6716767283f4675a05f5f8855b5b49c81783.tar.gz";
    sha256 = "06361kf2n22z10wlsmy9iqvj8p2rfsdsqkac6c14j0d10mflj126";
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
    rev = "dee12f1dcc828d82c2427bb041f212081f065a43";
    hash = "sha256-qpscXobqjRkPiSHtwskFELSsjFQ72REZyIX/AAr1VqU=";
  };
  "anthropic-skills-src" = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "e4bb5d960d87126ff3b3a8af1a104b7db67560ba";
    hash = "sha256-Gr9LatjawHHK9uKpoclWoiDHZ0NTpP3/4Pmeatl8p/Q=";
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
    rev = "5a37a6329fbad3666c3207392a6a7c0110e92efb";
    hash = "sha256-gGacyJJnu1wf2y1CKGVjIyVbTOBnkly2ouYQSbgPb0E=";
  };
  "trailofbits-skills-src" = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "149d7b21f4067765b82e67029730b42d228ef4b4";
    hash = "sha256-8NBnk9sFW1IMkd+qmTvLKweh3CkeJaALEZBLs3GaxlM=";
  };
  "remotion-skills-src" = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "89c8afa3eee9cdd83838ac31979c2ba1384615aa";
    hash = "sha256-paHzt7uvmo1xKyFmE3CGwdRxeVMwpmuS5Xxdv/QYqUY=";
  };
  "marketing-skills-src" = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "8fd2fcade2fd6629026e9dfe6d133b55b36968b9";
    hash = "sha256-Jq4dyfEjV7C+6x9VLsFk7Uuo58Uy3j9CUxX30+N9hC0=";
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
    rev = "abeeaf95660ba9e8b7c753eb38f441ca707a8823";
    hash = "sha256-fc5+qmchp1IQ/rQP1olWKC1eC4VdYhaB7YYzC3+JBe0=";
  };
}
