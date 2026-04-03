# Temporary lib exports — kept for backwards compatibility until
# systems/ directory is fully removed.
{inputs, ...}: {
  flake.lib = {
    mkHomeManager = import ../../lib/mk-home-manager.nix;
    mkNeovimPackages = import ../../lib/mk-neovim-packages.nix;
  };
}
