{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
}: let
  npm-packages = import ../fetcher/npm-packages.nix;

  # Main package
  mermaidCli = stdenv.mkDerivation rec {
    pname = "mermaid-cli";
    inherit (npm-packages.mermaid-cli) version;

    src = fetchurl {
      inherit (npm-packages.mermaid-cli) url;
      hash = npm-packages.mermaid-cli.url-hash;
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
      mkdir -p $out/lib/node_modules/mermaid-cli
      mkdir -p $out/bin

      # Copy all the necessary files
      cp -r source/package/* $out/lib/node_modules/mermaid-cli/

      # Create a wrapper script for the CLI
      makeWrapper ${nodejs}/bin/node $out/bin/mmdc \
        --add-flags "$out/lib/node_modules/mermaid-cli/bin/mermaid.js"
    '';

    meta = {
      description = "Generate diagrams and flowcharts from text in a similar manner as markdown";
      homepage = "https://github.com/mermaid-js/mermaid-cli";
      mainProgram = "mmdc";
    };
  };
in
  mermaidCli
