{
  config,
  osConfig ? {},
  lib,
  pkgs,
  ...
}: let
  ccstatusline = pkgs.callPackage ../../../apps/ccstatusline.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
  };
  agent-browser = pkgs.callPackage ../../../apps/agent-browser.nix {
    npm-packages = import ../../../apps/fetcher/npm-packages.nix;
    inherit (pkgs) playwright-driver;
  };
  herdr = pkgs.callPackage ../../../apps/herder.nix {};
  # isWorkstation lives on the OS-level config (darwin/nixos), not in the
  # home-manager scope, so read it via osConfig like media-apps.nix does.
  isWorkstation = (osConfig.my or {}).isWorkstation or config.my.isWorkstation;
in {
  home.packages =
    [agent-browser ccstatusline herdr]
    ++ (with pkgs; [
      llama-cpp
    ])
    # Graphify (pkgs.graphify) is a uv2nix-built venv carrying the heavy
    # graspologic/tree-sitter closure; scope it to Darwin workstations
    # (macbook-pro) — the only platform its uv.lock has been built against.
    ++ (lib.optional (pkgs.stdenv.hostPlatform.isDarwin && isWorkstation) pkgs.graphify)
    ++ (
      if pkgs.stdenv.hostPlatform.isDarwin
      then [(pkgs.writeShellScriptBin "docker" ''exec podman "$@"'')]
      else []
    );

  home.file.".config/herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+a"
    switch_workspace = "prefix+shift+1..9"
    focus_agent = "ctrl+1..9"
    split_vertical = "prefix+|"
    split_horizontal = "prefix+minus"
    goto = "prefix+s"

    [[keys.command]]
    key = "prefix+g"
    type = "pane"
    command = "lazygit"
    description = "run lazygit"

    [theme]
    name = "tokyo-night"
  '';
}
