{pkgs ? import <nixpkgs> {}}: let
  repos-src = import ./apps/fetcher/repos-src.nix {inherit pkgs;};
in
  pkgs.buildGoModule {
    pname = "container-digest";
    version = "0.1.0";

    src = repos-src.container-digest-src;

    vendorHash = "sha256-tEYuoxMp2vzti6QmcODbczVgOd8+Btzd1Apkep9VcI4=";

    # Specify the package to build
    subPackages = ["cmd/container-digest"];
  }
