{
  inputs,
  secrets,
  imports ? [],
  hostArgs ? {},
}: {
  useGlobalPkgs = true;
  useUserPackages = true;
  backupFileExtension = "backup";
  users.fdrake.imports =
    [
      ../modules/home-manager
      inputs.sops-nix.homeManagerModules.sops
      inputs.secrets.nixosModules.soft-secrets
      inputs.secrets.nixosModules.secrets
      inputs.nixvim.homeManagerModules.nixvim
      # ({pkgs, ...}: {
      #   home.packages =
      #     (builtins.attrValues (import ./mk-neovim-packages.nix {
      #       inherit pkgs;
      #       neovimPkgs = inputs.neovim.packages.${pkgs.system};
      #     }))
      #     ++ [inputs.neovim.packages.${pkgs.system}.default];
      # })
    ]
    ++ imports;
  extraSpecialArgs = {inherit inputs secrets hostArgs;};
}
