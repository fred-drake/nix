# Pi "@hsingjui/pi-hooks" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@hsingjui/pi-hooks`.
#
# The package ships TypeScript source files; pi can load TypeScript extensions
# directly and resolves relative imports within src/ at runtime. All peer deps
# are provided by pi core at runtime.
#
# Version + hash come from ./fetcher/pi-hooks.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-hooks";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@hsingjui/pi-hooks/-/pi-hooks-${pin.version}.tgz";
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

    # TypeScript extension tree — package.json registers ./src/pi-hooks.ts.
    cp -r src $out/

    runHook postInstall
  '';

  meta = {
    description = "Claude Code-compatible command hooks for the Pi coding agent";
    homepage = "https://pi.dev/packages/@hsingjui/pi-hooks?name=pi-hooks";
    license = lib.licenses.mit;
  };
}
