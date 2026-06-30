####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/e8a08808eb114c3972030c3090a468798fad13a8.tar.gz";
    sha256 = "1ixz638nv0dlpyy70by0sslxraa89ka6hq59glw4mm2cqdr8yrkg";
  };
  cc-marketplace-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "cf33ec47ef0b3294483222793f686e688d865015";
    hash = "sha256-xIvK8b2CHxlT5IUsW9+AdF3h9dtZid/hHSFAcJwRzDI=";
  };
  cc-skills-golang-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "466ea6dfd4aecb5c19caf29e7595e752c66c1a5d";
    hash = "sha256-+NLRtVyE8XbpVGhIrKqT1cB+9+lejlMat30iRX1m0YE=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "f268f7c953744036f0fa7e9d4b73535c04e57cb8";
    hash = "sha256-gvFbbT6uTPSvpFZdPvOiddZxs6amBdL/vm2qp97Dej4=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "bfa371d4cc38c4230c6f8774170659b3a1689081";
    hash = "sha256-h1tBXL7ble7eN8lMYuKJXkEg9HiZY/j70banpYVQ+aE=";
  };
  karpathy-skills-src = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  anthropic-skills-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "35414756ca55738e050562e272a6bbc6273aa926";
    hash = "sha256-7JB/zj2rBFdvbbFuGIFDXnm1TN26E67fRO1deQvzs34=";
  };
  vercel-agent-skills-src = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "f8a72b9603728bb92a217a879b7e62e43ad76c81";
    hash = "sha256-LSFC0Zxc4Lgisu5/r6qBF1R0X36hePkVPfbvbx48YdY=";
  };
  trailofbits-skills-src = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "cfe5d7b1619e47fb5b38b7e2561dad7e5f1e89af";
    hash = "sha256-hOA3v+QFGJLkw7OVPSzjtCZXS7zU792AfqGNdSNgsgA=";
  };
  remotion-skills-src = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "8dad6ec5c5c7cedee4d2aa620bb68386f8fe8eb9";
    hash = "sha256-7J6mMdFUsciro5f3ls6UGQZs+pfcisDe3rC9hz60qdQ=";
  };
  marketing-skills-src = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "8bfcdffb655f16e713940cd04fb08891899c47db";
    hash = "sha256-rvfvF9yTA8fRDu33Js+rKdc7p+78ijBhejdyi+zxRuM=";
  };
}
