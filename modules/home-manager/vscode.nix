{
  pkgs,
  inputs,
  ...
}: {
  mkVSCodePackages = pkgs: vscodePkgs: let
    mkVSCodeAlias = name: pkg:
      pkgs.runCommand "vscode-${name}" {} ''
        mkdir -p $out/bin
        ln -s ${pkg}/bin/code $out/bin/code-${name}
      '';
  in
    builtins.mapAttrs mkVSCodeAlias vscodePkgs;

  home.packages =
    (builtins.attrValues (mkVSCodePackages pkgs inputs.vscode.packages.${pkgs.system}))
    ++ [inputs.vscode.packages.${pkgs.system}.default];
}
