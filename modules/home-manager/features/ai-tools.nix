{
  pkgs,
  pkgsStable ? pkgs,
  ...
}: let
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
