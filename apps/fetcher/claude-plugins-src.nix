####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/bd7cf41fc8a468b136a9266633303ff4a011c7b4.tar.gz";
    sha256 = "1q5g2yjhzihliqjfa2glgg0xyk3x4ibblkzl972vmssilg9b884s";
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
    rev = "168ec1416e54a9f5732343031094fc6fe2e36955";
    hash = "sha256-ia0C6cJQ0kQLyDm5IxFNTwhMW0Ytg6sYDtMCayRubM0=";
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
    rev = "087309a1b73f186f152c55081eac71213d3005b5";
    hash = "sha256-H/YyzhEzqkEYT8Gi+IxJg9IAi3+c9NazH4Q6QY9lSeM=";
  };
  karpathy-skills-src = pkgs.fetchFromGitHub {
    owner = "forrestchang";
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
    rev = "c94841be3deae8a880fa1a9078979adac7ca3dbc";
    hash = "sha256-WpgldxCQdFBPrUA6RzTSUrL12m9VV1X0+gLzK6uberU=";
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
