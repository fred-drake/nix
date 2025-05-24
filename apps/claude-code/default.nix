{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
}: let
  npm-packages = import ../fetcher/npm-packages.nix;

  # Main package
  claudeCode = stdenv.mkDerivation rec {
    pname = "claude-code";
    version = npm-packages.claude-code.version;

    src = fetchurl {
      url = npm-packages.claude-code.url;
      hash = npm-packages.claude-code.url-hash;
    };

    nativeBuildInputs = [makeWrapper];

    # We don't need to build anything, just unpack and install
    dontBuild = true;

    unpackPhase = ''
      # Unpack the tarball
      mkdir -p source
      tar -xzf $src -C source
    '';

    installPhase = ''
      # Create the directory structure
      mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
      mkdir -p $out/bin

      # Copy all the necessary files
      cp -r source/package/* $out/lib/node_modules/@anthropic-ai/claude-code/

      # Create a wrapper script for the CLI
      makeWrapper ${nodejs}/bin/node $out/bin/claude \
        --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js"
    '';

    meta = {
      description = "Claude Code CLI tool";
      homepage = "https://www.anthropic.com/claude-code";
      mainProgram = "claude-code";
    };
  };
in
  claudeCode
