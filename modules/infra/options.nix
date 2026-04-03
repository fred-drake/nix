# Top-level shared options accessible to ALL flake-parts modules.
# These replace specialArgs/extraSpecialArgs for commonly-shared values.
{lib, ...}: {
  options.my = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The hostname of the current system (set per-host in feature modules)";
    };
    isWorkstation = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether this host is a full workstation";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "fdrake";
      description = "The primary user account name";
    };
  };
}
