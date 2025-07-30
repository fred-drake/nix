{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
  npm-packages,
}: let
  # Main package
  ccusage = stdenv.mkDerivation rec {
    pname = "ccusage";
    inherit (npm-packages.ccusage) version;

    src = fetchurl {
      inherit (npm-packages.ccusage) url;
      hash = npm-packages.ccusage.url-hash;
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
      mkdir -p $out/lib/node_modules/ccusage
      mkdir -p $out/bin

      # Copy all the necessary files
      cp -r source/package/* $out/lib/node_modules/ccusage/

      # Create a wrapper script for the CLI
      makeWrapper ${nodejs}/bin/node $out/bin/ccusage \
        --add-flags "$out/lib/node_modules/ccusage/dist/index.js"
    '';

    meta = {
      description = "Claude Code usage";
      homepage = "https://github.com/ryoppippi/ccusage";
      mainProgram = "ccusage";
    };
  };
in
  ccusage
