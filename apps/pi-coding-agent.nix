# Pi coding agent, built from the earendil-works/pi monorepo source rather than
# the nixpkgs package, so we can track upstream releases the day they land
# (nixpkgs lags even on unstable). Derivation adapted from nixpkgs'
# pkgs/by-name/pi/pi-coding-agent/package.nix; version + hashes come from the
# auto-generated pin in ./fetcher/pi-coding-agent.nix (run update-pi.sh to bump).
#
# Pi's published npm tarball ships no lockfile, but the monorepo does, so we
# build with buildNpmPackage from the tagged GitHub source.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  ripgrep,
  fd,
  makeBinaryWrapper,
  stdenvNoCC,
  pi-pin,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  inherit (pi-pin) version;

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    inherit (pi-pin) hash;
  };

  inherit (pi-pin) npmDepsHash;

  # WORKAROUND(pi-coding-agent): v0.81.1's source tag omits generated provider
  # model data; obtain the release artifact until upstream includes it in tags.
  pi-ai-data = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
    hash = pi-pin.piAiDataHash;
  };

  postPatch = ''
    tar -xzf ${finalAttrs."pi-ai-data"} --strip-components=3 \
      -C packages/ai/src/providers package/dist/providers/data
  '';

  npmWorkspace = "packages/coding-agent";

  # Skip native module rebuild for unneeded workspaces (e.g. canvas from web-ui)
  npmRebuildFlags = ["--ignore-scripts"];

  nativeBuildInputs = [makeBinaryWrapper];

  # Build workspace dependencies in order, then the coding-agent.
  # Upstream provides build:offline which builds all packages in order
  # without network access (using the restored pi-ai model data).
  buildPhase = ''
    runHook preBuild

    npm run build:offline

    runHook postBuild
  '';

  # npm workspace symlinks in the output point into packages/ which
  # doesn't exist there. Replace runtime deps with built content and
  # delete the rest.
  postInstall =
    ''
      local nm="$out/lib/node_modules/pi-monorepo/node_modules"

      # Replace workspace deps needed at runtime with real copies
      for ws in @earendil-works/pi-ai:packages/ai \
                @earendil-works/chord:packages/chord \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-codemode:packages/codemode \
                @earendil-works/pi-mcp:packages/mcp \
                @earendil-works/pi-telemetry:packages/telemetry \
                @earendil-works/pi-tui:packages/tui; do
        IFS=: read -r pkg src <<< "$ws"
        if [ -e "$nm/$pkg" ]; then
          rm -rf "$nm/$pkg"
          cp -r "$src" "$nm/$pkg"
        fi
      done

      # Delete remaining workspace symlinks
      find "$nm" -type l -lname '*/packages/*' -delete

      # Clean up now-dangling .bin symlinks
      find "$nm/.bin" -xtype l -delete
    ''
    + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
      # Remove foreign Linux binaries that make audit-tmpdir try to inspect ELF
      # RPATHs with patchelf
      rm -rf \
        "$nm/@anthropic-ai/sandbox-runtime/dist/vendor/seccomp" \
        "$nm/@anthropic-ai/sandbox-runtime/vendor/seccomp"
    '';

  postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${
    lib.makeBinPath [
      ripgrep
      fd
    ]
  }";

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = ["HOME"];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
