####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/c4d29764e820015ef913a00d1b8d7058aae11dce.tar.gz";
    sha256 = "0ziq9pqqzw2pi00wyp0z9084hnnnfapykvg884hc0c9w9fnd9r4w";
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
    rev = "9cfe9ad5246201fb651d5495202666bbcf3023cf";
    hash = "sha256-cNSMG83rmOgzxsMAHS55BPCVIG2gidHg50QmSqfvTz8=";
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
    rev = "871aa710b30d0775f5f18f0bf98f57cdb42047f4";
    hash = "sha256-0SC6bgtUD18UcjwzA0cf44Ub5hHuCUWf5JiJSDCWidU=";
  };
  karpathy-skills-src = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  agent-rules-skill-src = pkgs.fetchFromGitHub {
    owner = "netresearch";
    repo = "agent-rules-skill";
    rev = "76decb504e698ca884702c2388f9792892b17e6f";
    hash = "sha256-gvMGegCYqcg6fGtVQQORVY4FVdnnGJpPB1fsMlNlg2c=";
  };
  anthropic-skills-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "9d2f1ae187231d8199c64b5b762e1bdf2244733d";
    hash = "sha256-U7Nt1xrFOSOEm4vuWmy4pVsEyvv+Hj4sv8yXOofmwAw=";
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
