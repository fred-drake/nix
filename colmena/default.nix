{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";

  # Import host configurations
  adguard1 = import ./hosts/adguard1.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  adguard2 = import ./hosts/adguard2.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  overseerr = import ./hosts/overseerr.nix {inherit self nixpkgs-stable secrets sops-nix;};
  sonarr = import ./hosts/sonarr.nix {inherit self nixpkgs-stable secrets sops-nix;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  _adguard1 = adguard1._adguard1;
  _adguard2 = adguard2._adguard2;
  _overseerr = overseerr._overseerr;
  _sonarr = sonarr._sonarr;

  # Init configurations
  "adguard1-init" = adguard1."adguard1-init";
  "adguard2-init" = adguard2."adguard2-init";
  "overseerr-init" = overseerr."overseerr-init";
  "sonarr-init" = sonarr."sonarr-init";

  # Full configurations
  "adguard1" = adguard1."adguard1";
  "adguard2" = adguard2."adguard2";
  "overseerr" = overseerr."overseerr";
  "sonarr" = sonarr."sonarr";
}
