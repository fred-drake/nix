####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "48aa43517886014e90ee80a6461f9de75045369d";
    hash = "sha256-0NxVFMdpZp8mA2j78DPkxl1mh5ENjuO1qFTnYcngDWQ=";
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
}
