{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixarr,
  ...
}: let
  # Import host configurations
  headscale = import ./hosts/headscale.nix {inherit self nixpkgs-stable secrets sops-nix;};
  ironforge = import ./hosts/ironforge.nix {inherit self nixpkgs-stable secrets sops-nix nixarr;};
  orgrimmar = import ./hosts/orgrimmar.nix {inherit self nixpkgs-stable secrets sops-nix;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  inherit (headscale) _headscale;
  inherit (ironforge) _ironforge;
  inherit (orgrimmar) _orgrimmar;

  # Init configurations
  "headscale-init" = headscale."headscale-init";
  "ironforge-init" = ironforge."ironforge-init";
  "orgrimmar-init" = orgrimmar."orgrimmar-init";

  # Full configurations
  "headscale" = headscale."headscale";
  "ironforge" = ironforge."ironforge";
  "orgrimmar" = orgrimmar."orgrimmar";
}
