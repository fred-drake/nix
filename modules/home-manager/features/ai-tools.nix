{pkgs, ...}: let
  ccstatusline = pkgs.callPackage ../../../apps/ccstatusline.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
  };
  agent-browser = pkgs.callPackage ../../../apps/agent-browser.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
    inherit (pkgs) playwright-driver;
  };
in {
  home.packages =
    [agent-browser ccstatusline]
    ++ (with pkgs; [
      llama-cpp
    ])
    ++ (
      if pkgs.stdenv.hostPlatform.isDarwin
      then [(pkgs.writeShellScriptBin "docker" ''exec podman "$@"'')]
      else []
    );
}
