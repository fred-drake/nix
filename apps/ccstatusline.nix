{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
  npm-packages,
}: let
  # Main package
  ccstatusline = stdenv.mkDerivation rec {
    pname = "ccstatusline";
    inherit (npm-packages.ccstatusline) version;

    src = fetchurl {
      inherit (npm-packages.ccstatusline) url;
      hash = npm-packages.ccstatusline.url-hash;
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
      mkdir -p $out/lib/node_modules/ccstatusline
      mkdir -p $out/bin

      # Copy all the necessary files
      cp -r source/package/* $out/lib/node_modules/ccstatusline/

      # Create a wrapper script for the CLI
      makeWrapper ${nodejs}/bin/node $out/bin/ccstatusline \
        --add-flags "$out/lib/node_modules/ccstatusline/dist/ccstatusline.js"
    '';

    meta = {
      description = "Claude Code status line";
      homepage = "https://github.com/ryoppippi/ccstatusline";
      mainProgram = "ccstatusline";
    };
  };
in
  ccstatusline
