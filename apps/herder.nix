{
  lib,
  stdenv,
  rustPlatform,
  pkgs,
  zig_0_15,
  xcbuild,
  cctools,
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
  pin = import ./fetcher/herdr.nix;
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "herdr";
    inherit (pin) version cargoHash;

    __structuredAttrs = true;

    src = repos-src.herdr-src;

    zigDeps = zig_0_15.fetchDeps {
      inherit (finalAttrs) pname version;
      src = "${finalAttrs.src}/vendor/libghostty-vt";
      fetchAll = true;
      hash = pin.zigDepsHash;
    };

    nativeBuildInputs =
      [zig_0_15.hook]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        xcbuild # xcode-select/xcrun for Zig Darwin SDK discovery in the sandbox
        cctools # libtool for libghostty-vt's Zig build
      ];

    # Upstream binary tests are renamed, added, or changed between releases and
    # depend on host process details, so Nix-only patches for them are brittle.
    doCheck = false;

    dontUseZigBuild = true;
    dontUseZigCheck = true;
    dontUseZigInstall = true;

    postConfigure = ''
      export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
      cp -rL ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
      chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    meta = {
      description = "Agent multiplexer that lives in your terminal";
      homepage = "https://github.com/ogulcancelik/herdr";
      license = lib.licenses.agpl3Only;
      mainProgram = "herdr";
      platforms = lib.platforms.unix;
    };
  })
