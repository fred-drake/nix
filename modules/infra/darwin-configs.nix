{inputs, ...}: {
  flake.darwinConfigurations = import ../../systems/darwin.nix {
    inherit inputs;
    inherit
      (inputs)
      nixpkgs
      nixpkgs-stable
      nixpkgs-unstable
      nixpkgs-fred-unstable
      nixpkgs-fred-testing
      secrets
      nix-jetbrains-plugins
      nix4vscode
      homebrew-core
      homebrew-cask
      homebrew-bundle
      homebrew-fdrake
      homebrew-nikitabobko
      homebrew-sst
      homebrew-steipete
      ;
    outputs = inputs.self;
  };
}
