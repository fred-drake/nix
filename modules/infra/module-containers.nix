# deferredModule containers — the core dendritic mechanism.
# Any flake-parts module can write NixOS, Darwin, or Home Manager module
# fragments into these containers. The system builders (nixos.nix, darwin.nix)
# collect them and include them in each host's module list.
{lib, ...}: {
  options.flake.modules = {
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      description = "NixOS module fragments keyed by feature name";
    };
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      description = "Darwin module fragments keyed by feature name";
    };
    home-manager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      description = "Home Manager module fragments keyed by feature name";
    };
  };
}
