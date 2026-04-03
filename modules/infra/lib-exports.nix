{...}: {
  flake.lib = {
    mkHomeManager = import ../../lib/mk-home-manager.nix;
    mkNeovimPackages = import ../../lib/mk-neovim-packages.nix;
  };
}
