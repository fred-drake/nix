_: {
  programs.nixvim = {
    enable = true;
    # Use the home-manager-provided pkgs (already configured with allowUnfree)
    # instead of letting nixvim build its own instance from `nixpkgs.config`.
    # Self-constructing pkgs triggers infinite recursion in the new
    # `lsp.servers.*` package options, where the server submodule's
    # `_module.args.pkgs` ends up depending on `config`.
    nixpkgs.useGlobalPackages = true;
    imports = [
      ./dashboard.nix
      ./debugging.nix
      ./find.nix
      ./keys.nix
      ./language.nix
      ./options.nix
      ./plugins.nix
      ./sets.nix
      ./themes.nix
      ./transparent.nix
    ];
  };
}
