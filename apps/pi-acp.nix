# pi-acp is an ACP adapter that lets Buzz run the locally configured Pi agent.
# It is packaged separately from Pi because Buzz launches it as a custom harness.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  runCommand,
  nodejs,
}: let
  rawSrc = fetchFromGitHub {
    owner = "patrick-xin";
    repo = "pi-acp";
    rev = "be9b0612ed266886d5a282a87b874f9e28c21d0d";
    hash = "sha256-JXg+tKOg6soCjS7k7qq5EauWvd+BxeVghZqIiVM/F4o=";
  };
  # The upstream lockfile omits integrity metadata for three nested Pi packages.
  # Supply the repaired lockfile so Nix can verify every fetched tarball.
  src = runCommand "pi-acp-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/. $out/
    chmod -R +w $out
    cp ${./fetcher/pi-acp-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-acp";
    version = "0.1.0";

    inherit src;
    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-p9VuIb7nYCwxYVPDgEJzZo0tFPBszZx1EjYj/Ecz/Vw=";

    nativeBuildInputs = [makeWrapper];

    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -d "$out/lib/node_modules/pi-acp" "$out/bin"
      cp -r . "$out/lib/node_modules/pi-acp/"
      rm -f "$out/lib/node_modules/pi-acp/package-lock.json"
      makeWrapper ${nodejs}/bin/node "$out/bin/pi-acp" \
        --add-flags "$out/lib/node_modules/pi-acp/pi-acp.mjs"
      runHook postInstall
    '';

    meta = {
      description = "ACP adapter allowing Buzz to drive the Pi coding agent";
      homepage = "https://github.com/patrick-xin/pi-acp";
      license = lib.licenses.mit;
      mainProgram = "pi-acp";
    };
  }
