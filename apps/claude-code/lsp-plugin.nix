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

  # Custom LSP servers not available in the official marketplace.
  #
  # We use nixd rather than nil: nil 2025-06-13 added a hard guard that
  # panics (exit 101, "stdin/stdout is not pipe-like") unless both stdin
  # and stdout are a FIFO or socket. Claude Code's LSP harness (a Bun
  # standalone binary, here further wrapped by cmux) spawns the server
  # with non-pipe stdio on at least one fd, which trips that guard. nixd
  # has no such check (and is already this repo's Nix LSP for VSCode).
  customLspServers = {
    nix = {
      command = "nixd";
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
