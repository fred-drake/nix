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
}
