####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/9e150cfd48b87280cc76e035de04a11aa604e9c5.tar.gz";
    sha256 = "0xpv78x50vrw6y3240mhzvd2mvi0kp9ca42idkk34j57n4z2kn1z";
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
    rev = "123defac7bf3b6ca355652d1d8b8928f63df2f25";
    hash = "sha256-b3i3nrJL6OrxMQR3hFwYhF31BQU5REUw2vvl6UEQdZM=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "f2cbfbefebbfef77321e4c9abc9e949826bea9d7";
    hash = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };
  cmux-src = pkgs.fetchFromGitHub {
    owner = "manaflow-ai";
    repo = "cmux";
    rev = "4afeef69dea51621b86288944b6728a0227d7ee7";
    hash = "sha256-X+YbHcu69Ju+uvuf3HIe1CCO5Jdl9w6cZje9Mr/k9ys=";
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
    rev = "180115660cfb8a86b808f117475a01f54caf3bc5";
    hash = "sha256-j4mfYQ13f8/R9hU5z3nUb/fdXTqrk2qxIEeVK7e386U=";
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
