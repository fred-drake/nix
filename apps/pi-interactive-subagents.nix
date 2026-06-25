# Pi interactive subagents package (HazAT/pi-interactive-subagents), assembled
# for declarative loading by pi via a local-path `packages` entry (see
# modules/home-manager/features/pi.nix). This replaces:
#   pi install git:github.com/HazAT/pi-interactive-subagents
#
# The package declares only devDependencies and peerDependencies; there are no
# runtime npm dependencies. Pi provides all peer packages at runtime via its
# jiti module aliases (@mariozechner/* → bundled pi core, @sinclair/typebox).
# No npm install step is needed — the source files are copied as-is.
#
# Pi discovers the extension via the `pi.extensions` key in package.json:
#   "./pi-extension/subagents/index.ts"
# Bundled agent definitions under agents/ are read by the extension at runtime.
#
# Version + rev + hash come from ./fetcher/pi-interactive-subagents.nix.
# To update: grab the new HEAD rev from GitHub, re-run nix-prefetch-url
# --unpack on the archive tarball, convert with nix hash to-sri, and update
# the pin file.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-interactive-subagents";
  inherit (pin) version;

  src = fetchFromGitHub {
    owner = "HazAT";
    repo = "pi-interactive-subagents";
    inherit (pin) rev hash;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Copy the package manifest so pi can read pi.extensions
    cp package.json $out/

    # Extension entry point and all supporting TypeScript modules
    cp -r pi-extension $out/

    # Bundled agent definitions read by the extension at runtime
    cp -r agents $out/

    # Optional example config (gitignored upstream; documents status.enabled)
    cp config.json.example $out/

    runHook postInstall
  '';

  meta = {
    description = "Async interactive subagents for the pi coding agent (spawn, orchestrate, manage sub-agent sessions in multiplexer panes)";
    homepage = "https://github.com/HazAT/pi-interactive-subagents";
    license = lib.licenses.mit;
  };
}
