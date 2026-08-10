# Pi "pi-subagents" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
#
# Pi loads src/index.ts via jiti. The extension's dependencies are peer
# dependencies provided by pi core at runtime, so no node_modules are needed.
{
  lib,
  stdenvNoCC,
  pkgs,
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
  package = builtins.fromJSON (builtins.readFile "${repos-src.pi-subagents-src}/package.json");
in
  stdenvNoCC.mkDerivation {
    pname = "pi-subagents";
    inherit (package) version;
    src = repos-src.pi-subagents-src;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp package.json "$out/"
      cp -r src "$out/"

      runHook postInstall
    '';

    meta = {
      description = "Named interactive and background subagents for Pi";
      homepage = "https://github.com/edxeth/pi-subagents";
      license = lib.licenses.mit;
    };
  }
