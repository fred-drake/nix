{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Import all the individual host configurations
  imports = [
    ./hosts/adguard1.nix
    ./hosts/adguard2.nix
    ./hosts/overseerr.nix
    ./hosts/sonarr.nix
  ];
}
