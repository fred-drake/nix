# Shared options module providing config.my.* for host metadata.
# Injected into NixOS, Darwin, and Home Manager module systems so that
# deferred modules can self-guard with mkIf config.my.isWorkstation etc.
# Single source of truth — imported by nixos-infra.nix, darwin-infra.nix,
# and mk-home-manager.nix.
{lib, ...}: {
  options.my = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the current system being configured.";
    };
    isWorkstation = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether this host is a full workstation.";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "fdrake";
      description = "The primary user account name.";
    };
  };
}
