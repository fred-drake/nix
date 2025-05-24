{pkgs ? import <nixpkgs> {}}: let
  repos-src = import ./apps/fetcher/repos-src.nix {inherit pkgs;};
in
  pkgs.buildGoModule {
    pname = "npm-refresh";
    version = "0.1.0";

    src = repos-src.npm-refresh-src;

    vendorHash = "sha256-lDmlkZJWPj2eeDjdiELPKUmTTPedn5o3pfpXZOS6yFQ=";

    # Specify the package to build
    subPackages = ["cmd/npm-refresh"];
  }
