####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/093e91b2597fa5f352dfc217ed6d38ff4fa0ebcf.tar.gz";
    sha256 = "028x10irrl4xdg60m9p556yaprrg41b0kdid5n9aq17gj30yyc29";
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
    rev = "2e24bfb3279751a4fae0194e184d99139b240619";
    hash = "sha256-+B2q1Oz5W5n/aBOJVUYG+D5+S//nSffJN2wHwi7I6UU=";
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
    rev = "dd2e0e31f269ef6e936cfad94d06e74124b5dcd6";
    hash = "sha256-ojC3nHkpSlRJ4TSJFDrK93rJ1QVUUPjKm4W7ezjbVu8=";
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
    rev = "da20c92503b2e8ff1cf28ca81a0df4673debdbf7";
    hash = "sha256-BiZvEV7VK1AwhiGg+pNMgTUQmt4exevLWwL0Brx4YyE=";
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
