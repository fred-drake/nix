{
  pkgs,
  inputs,
  ...
}: let
  # Use centralized mkPkgs for stable channel to avoid npm 10+ ENOTCACHED
  # issues with tdd-guard. This uses the same overlays and config as all
  # other pkgsStable instantiations.
  pkgsStable =
    (import ../../../lib/mkPkgs.nix {
      inherit inputs;
      inherit (pkgs.stdenv.hostPlatform) system;
    })
  .pkgsStable;
  ccstatusline = pkgs.callPackage ../../../apps/ccstatusline.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
  };
  agent-browser = pkgs.callPackage ../../../apps/agent-browser.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
    inherit (pkgs) playwright-driver;
  };
  tdd-guard = pkgsStable.callPackage ../../../apps/tdd-guard.nix {};
  gws = pkgs.callPackage ../../../apps/gws.nix {};
in {
  home.packages =
    [agent-browser ccstatusline gws tdd-guard]
    ++ (with pkgs; [
      llama-cpp
    ])
    ++ (
      if pkgs.stdenv.hostPlatform.isDarwin
      then [(pkgs.writeShellScriptBin "docker" ''exec podman "$@"'')]
      else []
    );
}
