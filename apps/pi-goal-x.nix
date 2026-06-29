# Pi "pi-goal-x" package, assembled for declarative loading by pi via a
# local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:pi-goal-x`.
#
# pi-goal-x is a long-running goal extension that gives the agent a durable
# objective with a visible lifecycle: drafting, executing, pausing, resuming,
# and completing. Features include Sisyphus ordered-execution mode, structured
# task lists with subtasks, verification contracts, an independent completion
# auditor, and an above-editor status widget.
#
# The package ships TypeScript source only; pi loads extensions/goal.ts via
# jiti. All peer deps (@earendil-works/pi-coding-agent, @earendil-works/pi-ai,
# @earendil-works/pi-tui, typebox) are provided by pi core at runtime — no
# npm install step is needed.
#
# Key commands: /goals, /sisyphus, /goals-set, /goal-status, /goal-list,
#               /goal-focus, /goal-tweak, /goal-pause, /goal-resume,
#               /goal-settings, /goal-abort, /goal-clear
#
# Version + hash come from ./fetcher/pi-goal-x.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-goal-x";
  inherit (pin) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-goal-x/-/pi-goal-x-${pin.version}.tgz";
    inherit (pin) hash;
  };

  # npm tarballs extract into a "package/" subdirectory
  sourceRoot = "package";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Package manifest: pi reads pi.extensions from this to discover goal.ts
    cp package.json $out/

    # TypeScript extension files — pi loads them via jiti at runtime.
    # Subdirectories (prompts/, storage/, widgets/) must be preserved.
    cp -r extensions $out/

    runHook postInstall
  '';

  meta = {
    description = "Pi extension — durable long-running goals with Sisyphus mode, task lists, verification contracts, and completion auditor";
    homepage = "https://pi.dev/packages/pi-goal-x";
    license = lib.licenses.mit;
  };
}
