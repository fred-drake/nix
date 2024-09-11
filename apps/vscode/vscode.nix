# This file defines a set of common VSCode extensions to be installed.
# It takes two arguments: pkgs (for built-in extensions) and nix-vscode-extensions (for marketplace extensions).
{ pkgs, nix-vscode-extensions, lib }:

let
  extensions = (import ./extensions.nix) { pkgs = pkgs; lib = lib; };
  marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
in
{
  globalExtensions = with marketplace; [
    extensions.bbenoist.nix                  # Provides language support for Nix
    extensions.ms-vscode-remote.remote-ssh   # Enables remote development over SSH
    extensions.mikestead.dotenv              # Support for .env file syntax highlighting and autocompletion
    extensions.mobalic.jetbrains-dark-theme  # Dark theme inspired by JetBrains IDEs
    extensions.eamodio.gitlens               # Git supercharged - blame, code lens, and powerful comparison commands
    extensions.donjayamanne.githistory       # View and search git log, file history, compare branches or commits
    extensions.oderwat.indent-rainbow        # Colorizes indentation for improved readability
    extensions.wayou.vscode-todo-highlight   # Highlight TODO, FIXME and other annotations in code
    extensions.rodrigocfd.format-comment     # Format comments in code
    extensions.signageos.signageos-vscode-sops
    extensions.continue.continue
    extensions.pkief.material-icon-theme
    extensions.editorconfig.editorconfig
    extensions.saoudrizwan.claude-dev
  ];
}
