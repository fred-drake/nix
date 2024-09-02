# This file defines a set of common VSCode extensions to be installed.
# It takes two arguments: pkgs (for built-in extensions) and nix-vscode-extensions (for marketplace extensions).
{ pkgs, nix-vscode-extensions }:

let
  marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
in
{
  common = with pkgs.vscode-extensions; [
    bbenoist.nix                  # Provides language support for Nix
    ms-vscode-remote.remote-ssh   # Enables remote development over SSH
  ] ++ (with marketplace; [
    mikestead.dotenv              # Support for .env file syntax highlighting and autocompletion
    mobalic.jetbrains-dark-theme  # Dark theme inspired by JetBrains IDEs
    eamodio.gitlens               # Git supercharged - blame, code lens, and powerful comparison commands
    donjayamanne.githistory       # View and search git log, file history, compare branches or commits
    oderwat.indent-rainbow        # Colorizes indentation for improved readability
    wayou.vscode-todo-highlight   # Highlight TODO, FIXME and other annotations in code
    vscode-icons-team.vscode-icons # Adds icons to files and folders in the file explorer
    rodrigocfd.format-comment     # Format comments in code
  ]);
}