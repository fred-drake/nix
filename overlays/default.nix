{inputs, ...}: _final: prev: {
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.system}) wireguard-tools;
}
