{inputs, ...}: {
  flake.colmena = import ../../colmena {
    self = inputs.self;
    inherit
      (inputs)
      nixpkgs-stable
      nixpkgs-unstable
      nixos-hardware
      secrets
      sops-nix
      nixarr
      nixos-wsl
      ;
  };
}
