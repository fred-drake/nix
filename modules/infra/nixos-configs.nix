{inputs, ...}: {
  flake.nixosConfigurations = import ../../systems/nixos.nix {
    inherit inputs;
    inherit
      (inputs)
      colmena
      nixpkgs
      nixpkgs-stable
      nixpkgs-unstable
      nixpkgs-fred-unstable
      nixpkgs-fred-testing
      secrets
      nix-jetbrains-plugins
      nix4vscode
      ;
    outputs = inputs.self;
  };
}
