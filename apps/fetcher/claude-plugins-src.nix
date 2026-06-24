####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/720ba8d2a36dd64ccff3ed2a1f98712587d97362.tar.gz";
    sha256 = "0p2v1rg9r6vlcansiciik92b6rjyfgzby2rspkba5a4dlp6h3sc8";
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
    rev = "896224c4b1879920ab573417e68fd51d2ccc9072";
    hash = "sha256-+lT2a/qq0SF4k0PgnEDKiuidVlZX2p0vEso4d/5T1os=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "96221935ca6fe8cf852d764203073b6ce15002b7";
    hash = "sha256-RWQIfAmwQZwH7BHYXQxy8/D6K6amUFrX0ThVAGFItfo=";
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
    rev = "57546260929473d4e0d1c1bb75297be2fdfa1949";
    hash = "sha256-1D9otXxDvmKASBu/vtAEWv6kE+U+jG4OxZpRLZbGEF0=";
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
    rev = "ff4162dcb9cec5b7abe5ab039c868544b325275d";
    hash = "sha256-zzMfJ6+xtoXNi54Z1ef7CqlauKdptaenjrnIe8vAB+Q=";
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
