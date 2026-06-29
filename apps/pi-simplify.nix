# Pi "pi-simplify" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:pi-simplify`.
#
# The package ships pre-built JavaScript in dist/index.js; pi discovers it
# via the "pi.extensions" field in package.json. No TypeScript compilation
# step is needed (all peer deps are provided by pi core at runtime).
#
# Usage once installed:
#   /simplify              — review all uncommitted changes
#   /simplify --staged     — review only staged changes
#   /simplify src/foo.ts   — review specific files
#   /simplify --ref=main   — diff against a specific branch
#
# Version + hash come from ./fetcher/pi-simplify.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-simplify";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-simplify/-/pi-simplify-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Package manifest: pi reads pi.extensions from this
    cp package.json $out/

    # Pre-built ESM extension — pi loads ./dist/index.js
    # (registered under "pi.extensions" in package.json) via Node's native
    # ESM loader. All relative imports resolve within dist/ at runtime.
    cp -r dist $out/

    runHook postInstall
  '';

  meta = {
    description = "Pi extension that reviews recently changed code for clarity, consistency, and maintainability";
    homepage = "https://pi.dev/packages/pi-simplify";
    license = lib.licenses.mit;
  };
}
