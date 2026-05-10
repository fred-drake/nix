####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = builtins.fetchTarball {
    url = "https://github.com/anthropics/claude-plugins-official/archive/00679aef889efe36bb0389f81d70b6229a2013ee.tar.gz";
    sha256 = "0zd4ppn19scw33m1hd1jn99nlk2n0vxfdxvy9nrcv8g5si96j7fc";
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
    rev = "6ccf725ff46d3d2d78d7be76974ada4220c8bafd";
    hash = "sha256-/IrFEglReteOwk7pdpsOvheo2cKFQRMOF4bdlJvyMrk=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "f2cbfbefebbfef77321e4c9abc9e949826bea9d7";
    hash = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };
}
