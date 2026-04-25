####################################
# Auto-generated -- do not modify! #
####################################
{pkgs, ...}: {
  claude-plugins-official-src = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "020446a4294f09d9c32e60bff0c4ae8fb39205cb";
    hash = "sha256-ywyOB23pJaOQHf2nPvis1fNqpNPVUM59upxETzl6KCw=";
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
    rev = "937bc72b766e1c5980a8d34b8ed636fda19263a3";
    hash = "sha256-IHHPdoPH44sHDfV7c7RVr+S/CpayTk4j/3QHEIiab0k=";
  };
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "6efe32c9e2dd002d0c394e861e0529675d1ab32e";
    hash = "sha256-0WupTacT1jIwVBloj1i0RF7wIllVtP8eMPRl7VrXdbE=";
  };
}
