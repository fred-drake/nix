# Pi "context-mode" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:context-mode`.
#
# The package ships pre-built JavaScript in build/adapters/pi/extension.js;
# pi discovers it via the "pi.extensions" field in package.json.  No
# TypeScript compilation step is needed.
#
# SQLite dependency: build/db-base.js uses a three-way fallback:
#   1. bun:sqlite (Bun runtime — not used here)
#   2. node:sqlite (Node ≥ 22.5 — the Nix-provided Node satisfies this)
#   3. better-sqlite3 (native addon — intentionally NOT bundled)
# Because pi runs on Node ≥ 22.5 with FTS5 support, the native addon is
# never reached; we skip it to keep this derivation pure.
#
# The package also ships skills/ which pi discovers via "pi.skills" in
# package.json and makes available to the model automatically.
#
# Version + hash come from ./fetcher/pi-context-mode.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context-mode";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/context-mode/-/context-mode-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Package manifest: pi reads pi.extensions and pi.skills from this
    cp package.json $out/

    # Pre-built ESM extension files — pi loads ./build/adapters/pi/extension.js
    # (registered under "pi.extensions" in package.json) via Node's native
    # ESM loader.  All relative imports resolve within build/ at runtime.
    cp -r build $out/

    # Context-mode skills (context-mode, ctx-doctor, ctx-stats, etc.)
    # Pi discovers these via the "pi.skills" field in package.json.
    cp -r skills $out/

    runHook postInstall
  '';

  meta = {
    description = "Context window protection and session continuity for the pi coding agent";
    homepage = "https://pi.dev/packages/context-mode";
    license = lib.licenses.elastic20;
  };
}
