{
  pkgs,
  neovimPkgs,
}: let
  mkNeovimAlias = name: pkg:
    pkgs.runCommand "neovim-${name}" {} ''
      mkdir -p $out/bin
      ln -s ${pkg}/bin/nvim $out/bin/nvim-${name}
    '';
in
  builtins.mapAttrs mkNeovimAlias neovimPkgs
