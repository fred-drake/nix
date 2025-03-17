{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "nix4vscode";
  version = "unstable-2014-04-15";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = pname;
    rev = "ae9e1f04cd4cd230628f7dd70b41fbdfab040df9";
    hash = "sha256-Lj+om0JgCEzOlPrj/rZLqvEuTq86gRPvBlSkHWBO6lY=";
  };

  cargoHash = "sha256-4KDQyknEEqElfztvzGWaXICL0fIvPpPL1mSkZDkEY9Q=";

  meta = with lib; {
    description = "A tool generate nix expression for vscode extensions";
    homepage = "https://github.com/nix-community/nix4vscode";
    license = licenses.unlicense;
    maintainers = [];
  };
}
