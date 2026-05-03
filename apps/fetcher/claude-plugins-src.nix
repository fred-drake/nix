####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "b392f51899343f35a203260a4b344803de236d13";
    hash = "sha256-zUogHhL7MWXqpRDzjKI3giqyWJMArQDoSKooxhwfj/8=";
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
    rev = "e9761db859c6969b77a8fd0e8a243f4f28240211";
    hash = "sha256-BrRDo7tDagCNIXtZfh7zMKo6b16pSdh7Bu/gixEjVaA=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "e7a2d16476bf042e9add4699c9d018a90f86e4a6";
    hash = "sha256-8/M/S0BUYurZkFqe6LemVtBQnPSxBNfy1C7Q6f92hjE=";
  };
}
