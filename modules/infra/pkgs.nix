# Centralized pkgs variants — eliminates 12+ duplicate nixpkgs instantiations.
# All variants are defined once per system via perSystem and made available
# through _module.args so downstream modules can access them directly.
{inputs, ...}: {
  perSystem = {system, ...}: let
    baseOverlays = [
      (import ../../overlays/default.nix {inherit inputs;})
    ];
    vscodeOverlays =
      baseOverlays
      ++ [
        inputs.nix4vscode.overlays.forVscode
      ];
    mkPkgs = nixpkgsSrc: {
      overlays ? baseOverlays,
      cudaSupport ? false,
    }:
      import nixpkgsSrc {
        inherit system;
        config = {
          allowUnfree = true;
          inherit cudaSupport;
        };
        inherit overlays;
      };
  in {
    _module.args = {
      # Primary nixpkgs (nixos-unstable) with all overlays + nix4vscode
      pkgs = mkPkgs inputs.nixpkgs {overlays = vscodeOverlays;};

      pkgsUnstable = mkPkgs inputs.nixpkgs-unstable {overlays = vscodeOverlays;};
      pkgsStable = mkPkgs inputs.nixpkgs-stable {overlays = vscodeOverlays;};
      pkgsFredTesting = mkPkgs inputs.nixpkgs-fred-testing {overlays = vscodeOverlays;};
      pkgsFredUnstable = mkPkgs inputs.nixpkgs-fred-unstable {overlays = vscodeOverlays;};

      # CUDA-enabled pkgs (only meaningful on x86_64-linux, but defined everywhere
      # for simplicity — it just won't be used on other systems)
      pkgsCuda = mkPkgs inputs.nixpkgs {
        cudaSupport = true;
      };
    };
  };
}
