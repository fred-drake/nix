{
  pkgs,
  lib,
  ...
}: let
  name = "default";
  vscode-config = (import ./global-configuration.nix) {inherit pkgs lib;};
in {
  jsonSettings = pkgs.writeTextFile {
    name = "vscode-${name}-settings";
    text = builtins.toJSON vscode-config.globalSettings;
    destination = "/user/settings.json";
  };
  jsonKeyBindings = pkgs.writeTextFile {
    name = "vscode-${name}-keybindings";
    text = builtins.toJSON vscode-config.globalSettings;
    destination = "/user/keybindings.json";
  };
  code-with-extensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = vscode-config.globalExtensions;
  };
}
