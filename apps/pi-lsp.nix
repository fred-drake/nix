# Pi LSP extension (pi-lsp), assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:pi-lsp`.
#
# pi-lsp ships TypeScript source files loaded at runtime via jiti — no
# compilation step is needed. Its two runtime deps (vscode-jsonrpc and
# vscode-languageserver-protocol, plus the transitive
# vscode-languageserver-types) are bundled under node_modules/. The peer
# deps (@earendil-works/pi-coding-agent, @earendil-works/pi-tui, typebox)
# are provided by pi core at runtime and are intentionally not bundled.
#
# Version + hashes come from ./fetcher/pi-lsp.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}: let
  pi-lsp = fetchurl {inherit (pin.pi-lsp) url hash;};
  vscode-jsonrpc = fetchurl {inherit (pin.vscode-jsonrpc) url hash;};
  vscode-languageserver-protocol = fetchurl {inherit (pin.vscode-languageserver-protocol) url hash;};
  vscode-languageserver-types = fetchurl {inherit (pin.vscode-languageserver-types) url hash;};
in
  stdenvNoCC.mkDerivation {
    pname = "pi-lsp";
    inherit (pin.pi-lsp) version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # npm tarballs root everything under package/; strip it.
      mkdir -p $out/node_modules/vscode-jsonrpc
      mkdir -p $out/node_modules/vscode-languageserver-protocol
      mkdir -p $out/node_modules/vscode-languageserver-types

      tar -xzf ${pi-lsp} -C $out --strip-components=1
      tar -xzf ${vscode-jsonrpc} -C $out/node_modules/vscode-jsonrpc --strip-components=1
      tar -xzf ${vscode-languageserver-protocol} -C $out/node_modules/vscode-languageserver-protocol --strip-components=1
      tar -xzf ${vscode-languageserver-types} -C $out/node_modules/vscode-languageserver-types --strip-components=1

      runHook postInstall
    '';

    meta = {
      description = "Declarative Pi extension for LSP diagnostics and language-server navigation tools";
      homepage = "https://pi.dev/packages/pi-lsp";
      license = lib.licenses.mit;
    };
  }
