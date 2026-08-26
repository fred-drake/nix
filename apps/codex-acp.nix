{
  buildNpmPackage,
  fetchurl,
  npm-packages,
  runCommand,
}: let
  src = runCommand "codex-acp-src" {} ''
    mkdir $out
    tar -xzf ${fetchurl {
      inherit (npm-packages.codex-acp) url;
      hash = npm-packages.codex-acp.url-hash;
    }} --strip-components=1 -C $out
    cp ${./fetcher/codex-acp-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "codex-acp";
    inherit (npm-packages.codex-acp) version;
    inherit src;

    # Updated with the generated lockfile by update-codex-acp.sh.
    npmDepsHash = "sha256-FQCZdRHs2ngtBWNVpHx409P+HT4ezMGalFPCASNGSWA=";

    dontNpmBuild = true;

    meta = {
      description = "Agent Client Protocol adapter for the Codex CLI";
      homepage = "https://github.com/agentclientprotocol/codex-acp";
      mainProgram = "codex-acp";
    };
  }
