# Shared Darwin infrastructure — imported by modules/hosts/*.nix (Darwin hosts).
# The root parameter anchors path resolution to the repository root.
{
  inputs,
  config,
  root,
}: let
  inherit (inputs) darwin home-manager nix-homebrew secrets sops-nix;

  # Some casks take space on a limited Mac Mini, so only install them
  # on Mac Studio and MacBook Pro.
  non-mac-mini-casks = [
    "godot"
    "steam"
    "wine-stable"
    "winbox"
  ];

  # Homebrew tap wiring — shared across all Darwin hosts
  homebrewModule = {
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = "fdrake";
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko;
        "fred-drake/homebrew-tap" = inputs.homebrew-fdrake;
        "sst/homebrew-tap" = inputs.homebrew-sst;
        "steipete/homebrew-tap" = inputs.homebrew-steipete;
      };
      mutableTaps = false;
    };
  };

  darwinOptionsModule = import ./my-options-module.nix;

  # deferredModule fragments contributed by feature modules
  deferredDarwinModules = builtins.attrValues config.my.modules.darwin;
  deferredHmModules = builtins.attrValues config.my.modules.home-manager;

  # Common Darwin modules included in every Darwin system configuration
  commonModules =
    [
      darwinOptionsModule
      secrets.nixosModules.soft-secrets
      sops-nix.darwinModules.sops
      (root + "/modules/darwin")
      nix-homebrew.darwinModules.nix-homebrew
      homebrewModule
      home-manager.darwinModules.home-manager
    ]
    ++ deferredDarwinModules;

  mkDarwinSystem = {
    hostname,
    isWorkstation ? true,
    extraModules ? [],
    system ? "aarch64-darwin",
  }: let
    allPkgs = import ./mkPkgs.nix {inherit inputs system;};
  in
    darwin.lib.darwinSystem {
      inherit system;
      pkgs = allPkgs.pkgs;
      specialArgs = {
        inherit inputs non-mac-mini-casks;
        inherit (allPkgs) pkgsUnstable pkgsStable pkgsFredTesting pkgsFredUnstable;
      };
      modules =
        commonModules
        ++ [
          {
            my.hostName = hostname;
            my.isWorkstation = isWorkstation;
          }
          (root + "/modules/darwin/${hostname}")
        ]
        ++ extraModules;
    };
in {
  inherit commonModules deferredHmModules mkDarwinSystem;
}
