# Generates an LSP plugin directory from the official claude-plugins-official
# marketplace.json, merged with custom LSP server configs not available upstream.
#
# The result is a directory suitable for --plugin-dir containing:
#   .claude-plugin/plugin.json
#   .lsp.json
{
  pkgs,
  claude-plugins-official-src,
}: let
  marketplace =
    builtins.fromJSON
    (builtins.readFile "${claude-plugins-official-src}/.claude-plugin/marketplace.json");

  # Extract lspServers from all plugins that have them
  upstreamLspServers =
    builtins.foldl' (
      acc: plugin:
        if plugin ? lspServers
        then acc // plugin.lspServers
        else acc
    ) {}
    marketplace.plugins;

  # Custom LSP servers not available in the official marketplace
  customLspServers = {
    nix = {
      command = "nil";
      extensionToLanguage = {
        ".nix" = "nix";
      };
    };
  };

  mergedLspServers = upstreamLspServers // customLspServers;

  pluginJson = builtins.toJSON {
    name = "nix-managed-lsp";
    version = "1.0.0";
    description = "LSP servers generated from claude-plugins-official with custom additions";
  };

  lspJson = builtins.toJSON mergedLspServers;
in
  pkgs.runCommand "claude-lsp-plugin" {} ''
    mkdir -p $out/.claude-plugin
    echo '${pluginJson}' | ${pkgs.jq}/bin/jq . > $out/.claude-plugin/plugin.json
    echo '${lspJson}' | ${pkgs.jq}/bin/jq . > $out/.lsp.json
  ''
