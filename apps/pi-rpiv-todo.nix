# Pi "rpiv-todo" extension (@juicesharp/rpiv-todo), assembled for declarative
# loading by pi via a local-path `packages` entry
# (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:@juicesharp/rpiv-todo`.
#
# The package lives in the juicesharp/rpiv-mono monorepo at
# packages/rpiv-todo. We fetch the full monorepo, extract that subdir,
# and inject a generated lockfile (upstream ships none).
#
# Provides:
#   - `todo` tool — create/update/list/get/delete/clear tasks with 4-state
#     machine and blockedBy dependency tracking; tasks survive /reload and
#     conversation compaction via branch replay.
#   - `/todos` slash command — print current todo list grouped by status.
#   - Live aboveEditor overlay — auto-hides when empty; completed tasks drop
#     from the overlay at the start of the next agent response.
#
# Pi loads index.ts via jiti — no TypeScript compilation step needed.
# Peer deps (@earendil-works/pi-coding-agent, @earendil-works/pi-tui,
# @earendil-works/pi-ai, typebox, @juicesharp/rpiv-i18n) are intentionally
# NOT bundled; pi core provides them at runtime.
#
# Version + hashes come from ./fetcher/pi-rpiv-todo.nix (run
# ./fetcher/update-pi-rpiv-todo.sh to bump).
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
  src = runCommand "pi-rpiv-todo-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/packages/rpiv-todo/. $out/
    chmod -R +w $out
    cp ${./fetcher/pi-rpiv-todo-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-rpiv-todo";
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
      description = "Pi extension — persistent todo list with live overlay, /todos command, and blockedBy dependency tracking";
      homepage = "https://pi.dev/packages/@juicesharp/rpiv-todo";
      license = lib.licenses.mit;
    };
  }
