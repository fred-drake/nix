{inputs, ...}: final: prev: {
  wireguard-tools = inputs.nixpkgs-stable.legacyPackages.${prev.system}.wireguard-tools;
}
