{
  binutils,
  file,
  lib,
  pkgs,
  pkgsStatic ? pkgs.pkgsStatic,
  rustPlatform,
  static ? true,
}: let
  src = (import ./fetcher/repos-src.nix {inherit pkgs;}).buzz-src;
  builder =
    if static
    then pkgsStatic.rustPlatform
    else rustPlatform;
in
  builder.buildRustPackage {
    pname = "buzz-cli";
    version = "0.1.0-4749bc7b";
    inherit src;
    cargoHash = "sha256-7BQWBpHdmwt9BAbDlsEmk4PIYkeRDZwYIck3kgIJolo=";
    cargoBuildFlags = ["-p" "buzz-cli" "--bin" "buzz"];
    doCheck = false;
    doInstallCheck = true;
    nativeInstallCheckInputs = [file] ++ lib.optionals static [binutils];
    installPhase = ''
      runHook preInstall
      mapfile -t candidates < <(find target -type f -path '*/release/buzz' -perm -0100)
      test "''${#candidates[@]}" -eq 1
      install -Dm755 "''${candidates[0]}" "$out/bin/buzz"
      runHook postInstall
    '';
    installCheckPhase = ''
      "$out/bin/buzz" --help >/dev/null
      ${lib.optionalString static ''
        file "$out/bin/buzz" | grep -Eq 'static(-pie|ally) linked'
        ! readelf -l "$out/bin/buzz" | grep -q 'interpreter'
      ''}
    '';
  }
