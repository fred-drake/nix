{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    enable = true;
    imports = [
      ./dashboard.nix
      ./debugging.nix
      ./find.nix
      ./keys.nix
      ./language.nix
      ./options.nix
      ./plugins
      ./sets.nix
      ./themes.nix
      ./transparent.nix
    ];
  };
}
