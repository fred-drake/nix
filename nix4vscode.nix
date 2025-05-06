{
  lib,
  pkgs ? import <nixpkgs> {},
  rustPlatform,
}: let
  repos = import ./apps/fetcher/repos-src.nix {inherit pkgs;};
in
  rustPlatform.buildRustPackage {
    pname = "nix4vscode";
    version = "unstable-2014-04-15";

    src = repos.nix4vscode-src;

    cargoHash = "sha256-Kj9Z2qh1VBUyMBNXN260dAK4eVK27hn5iRKzZO79i4E=";

    meta = with lib; {
      description = "A tool to generate nix expressions for vscode extensions";
      homepage = "https://github.com/nix-community/nix4vscode";
      license = licenses.unlicense;
      maintainers = [];
    };
  }
