{
  buildNpmPackage,
  makeWrapper,
  nodejs,
  runCommand,
}: let
  package = builtins.fromJSON (builtins.readFile ./fetcher/codex-package.json);
in
  buildNpmPackage {
    pname = "codex";
    inherit (package) version;

    src = runCommand "codex-runtime-src" {} ''
      mkdir $out
      cp ${./fetcher/codex-package.json} $out/package.json
      cp ${./fetcher/codex-lock.json} $out/package-lock.json
    '';

    # Updated with the generated lockfile by update-codex-acp.sh.
    npmDepsHash = "sha256-ebdWkIpOozNCUgiDBrO5M7EruBvL07W9xCDirx3KHNw=";

    dontNpmBuild = true;
    nativeBuildInputs = [makeWrapper];

    postInstall = ''
      makeWrapper ${nodejs}/bin/node $out/bin/codex \
        --add-flags "$out/lib/node_modules/codex-runtime/node_modules/@openai/codex/bin/codex.js"
    '';

    meta = {
      description = "OpenAI Codex CLI compatible with codex-acp";
      homepage = "https://www.npmjs.com/package/@openai/codex";
      mainProgram = "codex";
    };
  }
