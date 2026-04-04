# Centralized pkgs variants — eliminates 12+ duplicate nixpkgs instantiations.
# All variants are defined once per system via perSystem and made available
# through _module.args so downstream modules can access them directly.
{inputs, ...}: {
  perSystem = {system, ...}: let
    allPkgs = import ../../lib/mkPkgs.nix {inherit inputs system;};
  in {
    _module.args = {
      inherit (allPkgs) pkgs pkgsUnstable pkgsStable pkgsFredTesting pkgsFredUnstable pkgsCuda;
    };
  };
}
