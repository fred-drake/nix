# Pi MCP adapter extension (pi-mcp-adapter), assembled for declarative loading
# by pi via a local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:pi-mcp-adapter`.
#
# The upstream repo ships no package-lock.json; we keep a generated one at
# apps/fetcher/pi-mcp-adapter-lock.json alongside the pin. npm can leave
# omitted dev dependency metadata in the generated lockfile, so the updater
# repairs registry entries that are missing integrity before computing
# npmDepsHash.
#
# Pi loads index.ts via jiti — no TypeScript compilation step needed.
# @earendil-works/pi-ai, pi-tui, and typebox are listed in the package's own
# `dependencies` (not peerDeps) and ARE bundled; pi's separate module roots
# mean they coexist with pi core's own copies without conflict.
#
# Version + hashes come from ./fetcher/pi-mcp-adapter.nix (run
# ./fetcher/update-pi-mcp-adapter.sh to bump).
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  pin,
}: let
  rawSrc = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    tag = "v${pin.version}";
    inherit (pin) hash;
  };
  # Inject the generated lockfile — upstream ships none.
  src = runCommand "pi-mcp-adapter-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/. $out/
    chmod -R +w $out
    cp ${./fetcher/pi-mcp-adapter-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-mcp-adapter";
    inherit (pin) version;
    inherit src;
    inherit (pin) npmDepsHash;

    # Lockfile was generated with --omit=dev --omit=peer; devDeps (pi-coding-agent,
    # test tools) are excluded. Peer dep (zod) is also excluded since it's
    # satisfied by the bundled zod in regular dependencies.
    npmFlags = ["--ignore-scripts" "--omit=dev" "--omit=peer"];

    # Pi loads index.ts directly via jiti — no compile step needed.
    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      # Copy source (TS files, etc.) + installed node_modules to output root
      cp -r . $out/
      # Drop build artifacts not needed at runtime
      rm -f $out/package-lock.json
      runHook postInstall
    '';

    meta = {
      description = "MCP (Model Context Protocol) adapter extension for the pi coding agent";
      homepage = "https://pi.dev/packages/pi-mcp-adapter";
      license = lib.licenses.mit;
    };
  }
