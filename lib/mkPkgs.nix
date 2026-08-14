# Centralized pkgs instantiation — called by host definitions and perSystem.
# Returns an attrset of all pkgs variants for a given system.
{
  inputs,
  system,
}: let
  # Overlays that expose flake-input packages through pkgs, so modules
  # never need `inputs` in their function arguments.
  inputPackageOverlays = [
    (_final: _prev: {
      hyprland-packages = inputs.hyprland.packages.${system};
      rose-pine-hyprcursor = inputs.rose-pine-hyprcursor.packages.${system}.default;
      zen-browser = inputs.zen-browser.packages.${system}.default;
      firefox-addons = inputs.firefox-addons.packages.${system};
    })
  ];
  baseOverlays =
    [
      (import ../overlays/default.nix {inherit inputs;})
      (import ../overlays/graphify.nix {inherit inputs;})
      (import ../overlays/pyicloud.nix {inherit inputs;})
    ]
    ++ inputPackageOverlays;
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
  inherit mkPkgs baseOverlays;

  pkgs = mkPkgs inputs.nixpkgs {};
  pkgsUnstable = mkPkgs inputs.nixpkgs-unstable {};
  pkgsStable = mkPkgs inputs.nixpkgs-stable {};
  pkgsFredTesting = mkPkgs inputs.nixpkgs-fred-testing {};
  pkgsFredUnstable = mkPkgs inputs.nixpkgs-fred-unstable {};
  pkgsCuda = mkPkgs inputs.nixpkgs {cudaSupport = true;};
}
