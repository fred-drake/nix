####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "0742692199b49af5c6c33cd68ee674fb2e679d50";
    hash = "sha256-5h7uXbqtuguCw9AMpEFJiKAH7ZmGgJJvm3yyec6+BXE=";
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
    rev = "bee9d0486d1deb542ef53f8a46d17c70b560891f";
    hash = "sha256-OMrUVUHtgpNUfTheYH2eOZ8nWbatqW25YY5cz6NU9jw=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "6efe32c9e2dd002d0c394e861e0529675d1ab32e";
    hash = "sha256-0WupTacT1jIwVBloj1i0RF7wIllVtP8eMPRl7VrXdbE=";
  };
}
