{
  pkgs,
  buildNpmPackage,
  buildGoModule,
  lib,
}: let
  repos-src = import ../apps/fetcher/repos-src.nix {inherit pkgs;};

  # Build the Go reporter module
  tdd-guard-go = buildGoModule rec {
    pname = "tdd-guard-go";
    version = "unstable";

    src = repos-src.tdd-guard-src;

    # Navigate to the Go reporter directory
    sourceRoot = "source/reporters/go";

    vendorHash = null;

    # Build with version information
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
    ];

    # Build the cmd/tdd-guard-go package
    subPackages = ["cmd/tdd-guard-go"];

    meta = with lib; {
      description = "TDD Guard Go reporter";
      homepage = "https://github.com/nizos/tdd-guard";
      license = licenses.mit;
      mainProgram = "tdd-guard-go";
    };
  };
in
  buildNpmPackage {
    pname = "tdd-guard";
    version = "0.0.1";

    src = repos-src.tdd-guard-src;
    npmDepsHash = "sha256-6wb9oaUVOcXlwnWwaFac3CK8BuW2jTUKxJkjc4Xrwis=";

    # We need to build the project to generate dist/
    # dontNpmBuild = true;

    # Skip postinstall scripts to prevent native binding downloads
    npmFlags = ["--ignore-scripts"];

    # Set environment variables to skip native module downloads
    preBuild = ''
      export NAPI_RS_FORCE_WASI=true
    '';

    # Patch package.json to remove problematic postinstall scripts if needed
    postPatch = ''
      if [ -f package.json ]; then
        ${pkgs.jq}/bin/jq 'if .dependencies."unrs-resolver" then .dependencies."unrs-resolver" |= . else . end |
                           if .scripts.postinstall then del(.scripts.postinstall) else . end' \
          package.json > package.json.tmp
        mv package.json.tmp package.json
      fi
    '';

    # Fix broken symlinks after installation
    postInstall = ''
      # Create missing directories that symlinks expect
      mkdir -p $out/lib/node_modules/tdd-guard/reporters/jest
      mkdir -p $out/lib/node_modules/tdd-guard/reporters/vitest

      # Alternative: Remove broken symlinks if directories aren't needed
      # rm -f $out/lib/node_modules/tdd-guard/node_modules/tdd-guard-jest
      # rm -f $out/lib/node_modules/tdd-guard/node_modules/tdd-guard-vitest

      # Install the Go reporter binary alongside the npm package
      mkdir -p $out/bin
      cp ${tdd-guard-go}/bin/tdd-guard-go $out/bin/
    '';

    meta = with lib; {
      description = "TDD Guard";
      homepage = "https://github.com/nizos/tdd-guard";
      license = licenses.mit;
      mainProgram = "tdd-guard";
    };
  }
