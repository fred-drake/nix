####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/78fa3df8d671bfe7ba4dcc972f1e12ae2b8750af.tar.gz";
    sha256 = "0by5r4wdiz9isa3lww5avcqyr2k9i0rfljyrfg6aqk2ll5ymbfgn";
  };
  cc-marketplace-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc";
    rev = "d672c5a40e665785c667650af71f35f0b107bf31";
    hash = "sha256-BRCw72D6tQVdHz95jma7DeuMy9dPklrTEN6zJezIR9U=";
  };
  cc-skills-golang-src = pkgs.fetchFromGitHub {
    owner = "samber";
    repo = "cc-skills-golang";
    rev = "a5e0e5997aac169b659e70cb826a20b489bc4c6c";
    hash = "sha256-qwITzZZdihbhLiG7zgKtbHSiq36hMzn6hPmCQz9b11M=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
    hash = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "dcab2aa58d60092966adc6005ccf6be1a35fedab";
    hash = "sha256-p/Ht/LBpyMohu/bfKTs+Feu5EZa+zi519Ek5o/0wIE0=";
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
    rev = "c070b9b5881183ea5f6e320ff06c46688becb13e";
    hash = "sha256-EEtkpVW0GO0OtoOh8ufBi73b9uRiIum+F0lVrjwrzgw=";
  };
  remotion-skills-src = pkgs.fetchFromGitHub {
    owner = "remotion-dev";
    repo = "skills";
    rev = "277510e78245ac0fa275d7cb6520d52e0ac2e212";
    hash = "sha256-XklSJY8xZMExl+BFtbYo+nQ8qLnmwWipkSZh9ykwt1s=";
  };
  marketing-skills-src = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "4b377f289bd37be457a7154626e109ec3affad50";
    hash = "sha256-NsYJVc4JdM1/GsezQvBE1QNZJkJ9j9R6bRJwNAlYwVk=";
  };
}
