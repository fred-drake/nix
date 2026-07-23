# Shared Darwin infrastructure — imported by modules/hosts/*.nix (Darwin hosts).
# The root parameter anchors path resolution to the repository root.
{
  inputs,
  config,
  root,
}: let
  inherit (inputs) darwin home-manager nix-homebrew secrets sops-nix;

  # Homebrew tap wiring — shared across all Darwin hosts
  homebrewModule = {
    pkgs,
    config,
    ...
  }: let
    # WORKAROUND(homebrew): Homebrew 6.0.11 lacks InstallSteps methods required
    # by current core casks; remove when nix-homebrew pins a compatible release.
    homebrewInstallSteps = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Homebrew/brew/6.0.12/Library/Homebrew/install_steps.rb";
      hash = "sha256-G1z3ITPwU1y3o6RQf+7JMd2a1lXAXKfBc+JA0SrtfpE=";
    };
  in {
    nix-homebrew = {
      enable = true;
      package = pkgs.runCommandLocal "brew-install-steps-fix" {} ''
        cp -r ${inputs.nix-homebrew.inputs.brew-src} "$out"
        chmod -R u+w "$out/Library/Homebrew"
        cp ${homebrewInstallSteps} "$out/Library/Homebrew/install_steps.rb"
      '';
      enableRosetta = true;
      user = config.my.username;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko;
        "sst/homebrew-tap" = inputs.homebrew-sst;
        "steipete/homebrew-tap" = inputs.homebrew-steipete;
        "facebook/homebrew-fb" = inputs.homebrew-facebook-fb;
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
      inherit (allPkgs) pkgs;
      specialArgs = {
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
