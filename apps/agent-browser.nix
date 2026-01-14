{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  playwright-driver,
  npm-packages,
}: let
  # Fetch zod from npm (required dependency)
  zod = fetchurl {
    url = "https://registry.npmjs.org/zod/-/zod-3.24.4.tgz";
    hash = "sha256-sGCtSAA+BQoY/dXVy4IUoJmZjhb9DtQ3dvtlWsDEtco=";
  };
in
  stdenv.mkDerivation rec {
    pname = "agent-browser";
    inherit (npm-packages.agent-browser) version;

    src = fetchurl {
      inherit (npm-packages.agent-browser) url;
      hash = npm-packages.agent-browser.url-hash;
    };

    nativeBuildInputs = [makeWrapper];

    dontBuild = true;

    unpackPhase = ''
      mkdir -p source
      tar -xzf $src -C source

      # Unpack zod
      mkdir -p zod
      tar -xzf ${zod} -C zod
    '';

    installPhase = ''
      mkdir -p $out/lib/node_modules/agent-browser
      mkdir -p $out/lib/node_modules/playwright-core
      mkdir -p $out/lib/node_modules/zod
      mkdir -p $out/bin

      # Copy agent-browser
      cp -r source/package/* $out/lib/node_modules/agent-browser/

      # Symlink playwright-core from nixpkgs playwright-driver
      cp -r ${playwright-driver}/* $out/lib/node_modules/playwright-core/

      # Copy zod
      cp -r zod/package/* $out/lib/node_modules/zod/

      # Create wrapper script that sets PLAYWRIGHT_BROWSERS_PATH
      makeWrapper $out/lib/node_modules/agent-browser/bin/agent-browser $out/bin/agent-browser \
        --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers}" \
        --set NODE_PATH "$out/lib/node_modules"
    '';

    meta = {
      description = "Headless browser automation CLI for AI agents";
      homepage = "https://github.com/nicholasrodriguez/agent-browser";
      mainProgram = "agent-browser";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  }
