# Pi "web access" extension (pi-web-access), assembled for declarative loading
# by pi via a local-path `packages` entry (see modules/home-manager/features/pi.nix).
# This replaces `pi install npm:pi-web-access`.
#
# The upstream repo ships no package-lock.json; we keep a generated one at
# apps/fetcher/pi-web-access-lock.json alongside the pin (generated with
# --omit=peer to exclude pi-core peer deps provided by pi at runtime).
#
# Pi loads index.ts via jiti — no TypeScript compilation step needed.
# The peer deps (@earendil-works/pi-ai, pi-coding-agent, pi-tui, typebox) are
# intentionally NOT bundled; pi core provides them at runtime.
#
# Version + hashes come from ./fetcher/pi-web-access.nix (run
# ./fetcher/update-pi-web-access.sh to bump).
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  pin,
}: let
  rawSrc = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    tag = "v${pin.version}";
    inherit (pin) hash;
  };
  # Inject the generated lockfile — upstream ships none.
  src = runCommand "pi-web-access-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/. $out/
    chmod -R +w $out
    cp ${./fetcher/pi-web-access-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-web-access";
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
      # Copy source (TS, skills/, etc.) + installed node_modules to output root
      cp -r . $out/
      # Drop build artifacts not needed at runtime
      rm -f $out/package-lock.json
      runHook postInstall
    '';

    meta = {
      description = "Web fetching and browsing extension for the pi coding agent";
      homepage = "https://pi.dev/packages/pi-web-access";
      license = lib.licenses.mit;
    };
  }
