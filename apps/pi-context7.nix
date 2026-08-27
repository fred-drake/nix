# Context7 Pi extension, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@upstash/context7-pi`.
#
# Pi discovers the extension, skills, and prompts from the `pi` field in the
# package manifest. Runtime peer dependencies are provided by pi core.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context7";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@upstash/context7-pi/-/context7-pi-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory.
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp package.json $out/
    cp -r extensions lib skills prompts $out/

    runHook postInstall
  '';

  meta = {
    description = "Context7 documentation retrieval extension for the Pi coding agent";
    homepage = "https://context7.com/docs/clients/pi";
    license = lib.licenses.mit;
  };
}
