# Pi "dynamic workflows" package (@quintinshaw/pi-dynamic-workflows), assembled
# for declarative loading by pi via a local-path `packages` entry (see
# modules/home-manager/features/pi.nix). This replaces `pi install npm:...`.
#
# Pi does NOT run `npm install` for local-path packages, so we build the package
# directory ourselves: the published tarball unpacked, plus its single runtime
# dependency (acorn — dependency-free, pure JS) under node_modules/. The peer
# deps (@earendil-works/pi-*, typebox) are provided by pi core at runtime and are
# intentionally not bundled.
#
# Version + hashes come from ./fetcher/pi-dynamic-workflows.nix (run
# ./fetcher/update-pi-dynamic-workflows.sh to bump).
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}: let
  workflows = fetchurl {inherit (pin.workflows) url hash;};
  acorn = fetchurl {inherit (pin.acorn) url hash;};
in
  stdenvNoCC.mkDerivation {
    pname = "pi-dynamic-workflows";
    inherit (pin.workflows) version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # npm tarballs root everything under package/; strip it.
      mkdir -p $out/node_modules/acorn
      tar -xzf ${workflows} -C $out --strip-components=1
      tar -xzf ${acorn} -C $out/node_modules/acorn --strip-components=1

      runHook postInstall
    '';

    meta = {
      description = "Claude Code-style dynamic workflows extension for the pi coding agent";
      homepage = "https://pi.dev/packages/@quintinshaw/pi-dynamic-workflows";
      license = lib.licenses.mit;
    };
  }
