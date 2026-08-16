{
  buildNpmPackage,
  makeWrapper,
  nodejs,
  runCommand,
}:
buildNpmPackage {
  pname = "codex";
  version = "0.147.0";

  src = runCommand "codex-runtime-src" {} ''
    mkdir $out
    cp ${./fetcher/codex-package.json} $out/package.json
    cp ${./fetcher/codex-lock.json} $out/package-lock.json
  '';

  npmDepsHash = "sha256-22pcZdl68Bt/THvCjaS69nOZGgYlAdR461o4xRAAndg=";

  dontNpmBuild = true;
  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    makeWrapper ${nodejs}/bin/node $out/bin/codex \
      --add-flags "$out/lib/node_modules/codex-runtime/node_modules/@openai/codex/bin/codex.js"
  '';

  meta = {
    description = "OpenAI Codex CLI compatible with codex-acp 1.2.0";
    homepage = "https://www.npmjs.com/package/@openai/codex";
    mainProgram = "codex";
  };
}
