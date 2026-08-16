{
  binutils,
  file,
  lib,
  pkgs,
  pkgsStatic ? pkgs.pkgsStatic,
  rustPlatform,
  static ? false,
}: let
  src = (import ./fetcher/repos-src.nix {inherit pkgs;}).buzz-src;
  builder =
    if static
    then pkgsStatic.rustPlatform
    else rustPlatform;
in
  builder.buildRustPackage {
    pname = "buzz-acp";
    version = "0.1.0-4749bc7b-owner-shutdown-exit";
    inherit src;
    patches = [./buzz-acp-owner-shutdown-exit.patch];
    cargoHash = "sha256-7BQWBpHdmwt9BAbDlsEmk4PIYkeRDZwYIck3kgIJolo=";
    cargoBuildFlags = ["-p" "buzz-acp" "--bin" "buzz-acp"];
    preBuild = ''
      export RUSTFLAGS="''${RUSTFLAGS:+$RUSTFLAGS }--remap-path-prefix=$NIX_BUILD_TOP=/build"
      export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:+$NIX_CFLAGS_COMPILE }-ffile-prefix-map=$NIX_BUILD_TOP=/build"
    '';
    prePatch = ''
      echo "5768fd5ebbdb1f7c2978e145ee4bb21985f7e7beb63c58cd4d9a44927e03681b  crates/buzz-acp/src/lib.rs" \
        | sha256sum -c -
      echo "81d7d727d7c598ed7ffc4b500a0cdc9cc82b06a8767313f791636f37e413c46d  crates/buzz-acp/src/main.rs" \
        | sha256sum -c -
    '';
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      cargo test -p buzz-acp --lib always_on_zero_disables_expiry_after_7200_seconds
      cargo test -p buzz-acp --lib owner_shutdown
      cargo test -p buzz-acp --lib test_mentions_mode_default_kinds
      cargo test -p buzz-acp --lib test_match_event_require_mention
      cargo test -p buzz-acp --lib test_dm_admits_owner_and_sibling_in_every_responding_mode
      cargo test -p buzz-acp --lib test_dm_rejects_stranger_under_anyone
      runHook postCheck
    '';
    doInstallCheck = true;
    nativeInstallCheckInputs = [file] ++ lib.optionals static [binutils];
    installPhase = ''
      runHook preInstall
      mapfile -t candidates < <(find target -type f -path '*/release/buzz-acp' -perm -0100)
      test "''${#candidates[@]}" -eq 1
      install -Dm755 "''${candidates[0]}" "$out/bin/buzz-acp"
      runHook postInstall
    '';
    postFixup = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      # Darwin's linker writes a random LC_UUID, then signs that value. Normalize
      # it after stripping and recreate a deterministic ad-hoc signature.
      ${pkgs.python3}/bin/python3 - "$out/bin/buzz-acp" <<'PY'
      import struct
      import sys
      from pathlib import Path

      path = Path(sys.argv[1])
      data = bytearray(path.read_bytes())
      if data[:4] != b"\xcf\xfa\xed\xfe":
          raise SystemExit("expected a little-endian 64-bit Mach-O")
      command_count = struct.unpack_from("<I", data, 16)[0]
      offset = 32
      for _ in range(command_count):
          command, size = struct.unpack_from("<II", data, offset)
          if command == 0x1B:
              data[offset + 8 : offset + 24] = bytes(16)
              path.write_bytes(data)
              break
          offset += size
      else:
          raise SystemExit("LC_UUID not found")
      PY
      ${pkgs.darwin.sigtool}/bin/codesign -f -s - "$out/bin/buzz-acp"
    '';
    installCheckPhase = ''
      "$out/bin/buzz-acp" --help >/dev/null
      ${lib.optionalString static ''
        file "$out/bin/buzz-acp" | grep -Eq 'static(-pie|ally) linked'
        ! readelf -l "$out/bin/buzz-acp" | grep -q 'interpreter'
      ''}
    '';
  }
