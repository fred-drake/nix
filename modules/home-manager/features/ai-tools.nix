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
  herdr-core = pkgs.callPackage ../../../apps/herdr-core.nix {};
  home = config.home.homeDirectory;
  # isWorkstation lives on the OS-level config (darwin/nixos), not in the
  # home-manager scope, so read it via osConfig like media-apps.nix does.
  isWorkstation = (osConfig.my or {}).isWorkstation or config.my.isWorkstation;
in {
  home = {
    packages =
      [agent-browser ccstatusline herdr herdr-core]
      ++ (with pkgs; [
        llama-cpp
        python313Packages.huggingface-hub
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

    file = {
      ".local/bin/herdr-core" = {
        source = "${herdr-core}/bin/herdr-core";
        force = true;
      };
      ".local/bin/hc" = {
        source = "${herdr-core}/bin/hc";
        force = true;
      };
    };
  };

  # Run herdr-core directly under launchd (HC_LAUNCHD_DIRECT=1) so its
  # responsible_pid stays alive and macOS Sequoia Local Network Privacy can
  # resolve the binary path and allow LAN connections.
  launchd.agents.herdr-core = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && isWorkstation) {
    enable = true;
    config = {
      Label = "dev.herdr.core";
      ProgramArguments = [
        "${herdr-core}/bin/herdr-core"
        "serve"
      ];
      EnvironmentVariables = {
        HC_LAUNCHD_DIRECT = "1";
        PATH = "${home}/.local/bin:${home}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      ProcessType = "Interactive";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
    };
  };
}
