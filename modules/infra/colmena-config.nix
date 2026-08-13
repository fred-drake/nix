{
  inputs,
  config,
  lib,
  ...
}: let
  nixosOptionsModule = import ../../lib/my-options-module.nix;

  # Desktop deferred modules (gnome, hyprland, gaming, nvidia, pipewire,
  # gpu-passthrough) reference NixOS options that don't exist on Colmena
  # servers using the minimal.nix profile. mkIf false still triggers option
  # validation, so we must exclude them. Only server-compatible modules
  # (those that use only base NixOS options) are passed through.
  desktopOnlyModules = ["gaming" "nvidia-cuda" "pipewire-audio" "hyprland" "gnome-desktop" "gpu-passthrough"];
  deferredNixosModules = builtins.attrValues (
    lib.filterAttrs (name: _: !builtins.elem name desktopOnlyModules) config.my.modules.nixos
  );

  # Home Manager feature modules for Colmena hosts. Pi is a workstation-only
  # tool: its extension source is Linux-only at evaluation time, which prevents
  # Darwin controllers from evaluating the x86_64-linux Anton and gnomeregan
  # configurations. Darwin hosts continue to receive the full feature set.
  deferredHmModules = builtins.attrValues (lib.removeAttrs config.my.modules.home-manager ["pi"]);
in {
  flake.colmena = import ../../colmena {
    inherit inputs;
    inherit (inputs) self;
    inherit
      (inputs)
      nixpkgs-stable
      nixpkgs-unstable
      nixos-hardware
      secrets
      sops-nix
      nixarr
      nixos-wsl
      home-manager
      nixvim
      nix-index-database
      ;
    inherit nixosOptionsModule deferredNixosModules deferredHmModules;
  };
}
