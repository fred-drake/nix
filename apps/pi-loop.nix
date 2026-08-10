# Pi "pi-loop" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@usirin/pi-loop`.
#
# The extension implements Claude Code-style `/loop` command support. Pi loads
# extensions/loop.ts via jiti; its peer dependencies are provided by pi core.
#
# Version + hash come from ./fetcher/pi-loop.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-loop";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@usirin/pi-loop/-/pi-loop-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Package manifest: pi reads pi.extensions from this.
    cp package.json $out/

    # Extension entry point loaded directly by pi via jiti.
    cp -r extensions $out/

    runHook postInstall
  '';

  meta = {
    description = "Claude Code-style /loop command for pi-coding-agent";
    homepage = "https://github.com/usirin/pi-loop";
    license = lib.licenses.mit;
  };
}
