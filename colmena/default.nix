{
  inputs,
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixos-wsl,
  secrets,
  sops-nix,
  nixarr,
  home-manager,
  nixvim,
  nix-index-database,
  nixosOptionsModule,
  deferredNixosModules,
  deferredHmModules,
  ...
}: let
  # Import host configurations
  headscale = import ./hosts/headscale.nix {inherit self nixpkgs-stable secrets sops-nix nixosOptionsModule deferredNixosModules;};
  ironforge = import ./hosts/ironforge.nix {inherit self nixpkgs-stable secrets sops-nix nixarr nixosOptionsModule deferredNixosModules;};
  orgrimmar = import ./hosts/orgrimmar.nix {inherit self nixpkgs-stable secrets sops-nix nixosOptionsModule deferredNixosModules;};
  undercity = import ./hosts/undercity.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix nixosOptionsModule deferredNixosModules;};
  anton = import ./hosts/anton.nix {inherit self nixpkgs-stable nixpkgs-unstable nixos-wsl secrets sops-nix home-manager nixvim nix-index-database nixosOptionsModule deferredNixosModules deferredHmModules;};
  gnomeregan = import ./hosts/gnomeregan.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix home-manager nixvim nix-index-database nixosOptionsModule deferredNixosModules deferredHmModules;};
  stormwind = import ./hosts/stormwind.nix {inherit self nixpkgs-stable secrets sops-nix nixosOptionsModule deferredNixosModules;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
    # gnomeregan tracks unstable end-to-end (modules + packages) because the
    # workstation home-manager features it loads reference unstable-only attrs
    # (prettier, lndir, …). Stable modules + unstable pkgs hits real mismatches
    # (e.g. systemd unit skew), so unstable hosts must align the module set
    # with the package set here rather than only overriding nixpkgs.pkgs.
    # gnomeregan uses a bare nixpkgs (no mkPkgs overlays), so apply the
    # glance-from-main overlay here directly. See overlays/glance.nix.
    nodeNixpkgs.gnomeregan = import nixpkgs-unstable {
      system = "x86_64-linux";
      overlays = [
        (import ../overlays/glance.nix {inherit inputs;})
        (import ../overlays/pyicloud.nix {inherit inputs;})
      ];
    };
    # anton (WSL) also tracks unstable end-to-end. It previously used only
    # nixpkgs.pkgs = unstable on top of the stable module set, but unstable
    # systemd 260.1 dropped example/systemd/system/autovt@.service while the
    # stable getty.nix module still references it, breaking system-units.
    nodeNixpkgs.anton = import nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  };

  # Merge all host configurations
  # Base configurations
  inherit (headscale) _headscale;
  inherit (ironforge) _ironforge;
  inherit (orgrimmar) _orgrimmar;
  inherit (undercity) _undercity;
  inherit (anton) _anton;
  inherit (gnomeregan) _gnomeregan;
  inherit (stormwind) _stormwind;

  # Init configurations
  "headscale-init" = headscale."headscale-init";
  "ironforge-init" = ironforge."ironforge-init";
  "orgrimmar-init" = orgrimmar."orgrimmar-init";
  "undercity-init" = undercity."undercity-init";
  "anton-init" = anton."anton-init";
  "gnomeregan-init" = gnomeregan."gnomeregan-init";
  "stormwind-init" = stormwind."stormwind-init";

  # Full configurations
  "headscale" = headscale."headscale";
  "ironforge" = ironforge."ironforge";
  "orgrimmar" = orgrimmar."orgrimmar";
  "undercity" = undercity."undercity";
  "anton" = anton."anton";
  "gnomeregan" = gnomeregan."gnomeregan";
  "stormwind" = stormwind."stormwind";
}
