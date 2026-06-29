# Pi "ask user question" extension (@juicesharp/rpiv-ask-user-question),
# assembled for declarative loading by pi via a local-path `packages` entry
# (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@juicesharp/rpiv-ask-user-question`.
#
# The package lives in the juicesharp/rpiv-mono monorepo at
# packages/rpiv-ask-user-question. We fetch the full monorepo, extract
# that subdir, and inject a generated lockfile (upstream ships none).
#
# Pi loads index.ts via jiti — no TypeScript compilation step needed.
# Peer deps (@earendil-works/pi-coding-agent, @earendil-works/pi-tui,
# typebox, @juicesharp/rpiv-i18n) are intentionally NOT bundled; pi core
# provides them at runtime.
#
# Version + hashes come from ./fetcher/pi-ask-user-question.nix (run
# ./fetcher/update-pi-ask-user-question.sh to bump).
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  pin,
}: let
  rawSrc = fetchFromGitHub {
    owner = "juicesharp";
    repo = "rpiv-mono";
    tag = "v${pin.version}";
    inherit (pin) hash;
  };
  # Extract the package subdir from the monorepo and inject the generated lockfile.
  src = runCommand "pi-ask-user-question-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/packages/rpiv-ask-user-question/. $out/
    chmod -R +w $out
    cp ${./fetcher/pi-ask-user-question-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-ask-user-question";
    inherit (pin) version;
    inherit src;
    inherit (pin) npmDepsHash;

    # Lockfile was generated with --omit=peer; runtime peer deps are
    # provided by pi core and are not in the lockfile.
    npmFlags = ["--ignore-scripts" "--omit=peer"];

    # Pi loads index.ts directly via jiti — no compile step needed.
    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      # Copy source (TS, etc.) + installed node_modules to output root
      cp -r . $out/
      # Drop build artifacts not needed at runtime
      rm -f $out/package-lock.json
      runHook postInstall
    '';

    meta = {
      description = "Structured questionnaire tool for the pi coding agent — ask typed clarifying questions instead of guessing";
      homepage = "https://pi.dev/packages/@juicesharp/rpiv-ask-user-question";
      license = lib.licenses.mit;
    };
  }
