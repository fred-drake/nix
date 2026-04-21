####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "777db5c30b30fd1809cdc0ed26a6b2cec57628dd";
    hash = "sha256-WzemE/1QCDeVwcJS5iaQBFIUvLvACWmW3TCaF6JHNZQ=";
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
    rev = "26524a3381ed93b43f5983c0e1dc53b0dd04af1d";
    hash = "sha256-QA1XWRl36YYcYKts36RQ5SjTsReiSRyOOARnB8XTC1c=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "b55764852ac78870e65c6565fb585b6cd8b3c5c9";
    hash = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
  };
}
