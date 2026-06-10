####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/de573bd84695c6657b28f05ffe32c37bb54d1f55.tar.gz";
    sha256 = "1dpxlxhr6m1s290krss8lv7fxqzzab8yrgpnwc07agjcw2p3vm1g";
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
    rev = "919d2d44054b06c90c0fb0ac43bc8bf8143ce323";
    hash = "sha256-XO6wG+Gg6g8CxUB1aueTzxQj+98SNWrTJdDalUih25k=";
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
    rev = "4ec6f84b61cd3c931046c3e6e398f3ae7de372f7";
    hash = "sha256-E/NG+zuNYaZYM0FTV6ZFYQovcVEWCQEbe8PKuEu7rT8=";
  };
  trailofbits-skills-src = pkgs.fetchFromGitHub {
    owner = "trailofbits";
    repo = "skills";
    rev = "d5fe2e6a7896236c3102fd5477e833623ad70298";
    hash = "sha256-VCIy7AaKLHD4paZUDpuAKkchRbGyaw3KY/khS55ypw0=";
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
    rev = "7f4af1ea8e7809e0142c55bf19243a706f539c25";
    hash = "sha256-R2X+QYVOUvXowHhsWTOj5LN+jvkFYGCdrqPXh0bCeM8=";
  };
}
