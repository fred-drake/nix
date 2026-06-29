# Pi "hypa" extension (@hypabolic/pi-hypa), assembled for declarative loading
# by pi via a local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@hypabolic/pi-hypa`.
#
# The extension rewrites shell commands through the hypa CLI to compress noisy
# tool output before it reaches the context window.  Pi loads extensions/index.ts
# via jiti — no TypeScript compilation step needed.
#
# Runtime dependency: the hypa CLI binary.  The extension resolves it via PATH
# first (see resolveHypaBinary in extensions/rewrite-client.ts), so providing
# apps/hypa.nix in home.packages is sufficient.  The bundled @hypabolic/hypa
# npm package (which shells out to a platform binary) is intentionally NOT
# included here; the Nix-managed binary satisfies the same contract.
#
# The postinstall.js shim installer is skipped (not needed in Nix; hypa is on PATH).
#
# Version + hash come from ./fetcher/pi-hypa.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-hypa";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@hypabolic/pi-hypa/-/pi-hypa-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Package manifest: pi reads pi.extensions from this to discover the extension
    cp package.json $out/

    # Extension entry point and all supporting TypeScript modules
    cp -r extensions $out/

    # README for reference
    cp README.md $out/

    # Intentionally omitted:
    #   scripts/postinstall.js — would install a hypa CLI shim; not needed
    #                            because apps/hypa.nix provides it via PATH.

    runHook postInstall
  '';

  meta = {
    description = "Pi extension that keeps noisy tool output out of your context window via Hypa";
    homepage = "https://github.com/Hypabolic/Hypa/tree/main/packages/pi-hypa";
    license = lib.licenses.free; # FSL-1.1-ALv2
  };
}
