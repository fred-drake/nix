# Centralized pkgs instantiation — called by host definitions and perSystem.
# Returns an attrset of all pkgs variants for a given system.
{
  inputs,
  system,
}: let
  baseOverlays = [
    (import ../overlays/default.nix {inherit inputs;})
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
  inherit mkPkgs baseOverlays vscodeOverlays;

  pkgs = mkPkgs inputs.nixpkgs {overlays = vscodeOverlays;};
  pkgsUnstable = mkPkgs inputs.nixpkgs-unstable {overlays = vscodeOverlays;};
  pkgsStable = mkPkgs inputs.nixpkgs-stable {overlays = vscodeOverlays;};
  pkgsFredTesting = mkPkgs inputs.nixpkgs-fred-testing {overlays = vscodeOverlays;};
  pkgsFredUnstable = mkPkgs inputs.nixpkgs-fred-unstable {overlays = vscodeOverlays;};
  pkgsCuda = mkPkgs inputs.nixpkgs {cudaSupport = true;};
}
