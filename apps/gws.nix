{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  binaryMeta = import ./fetcher/gws-binary.nix;

  platform = binaryMeta.platforms.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "gws";
    inherit (binaryMeta) version;

    src = fetchurl {
      url = "${binaryMeta.baseUrl}/v${binaryMeta.version}/${platform.artifact}";
      inherit (platform) hash;
    };

    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp gws $out/bin/gws
      chmod +x $out/bin/gws
      runHook postInstall
    '';

    meta = {
      description = "Google Workspace CLI";
      homepage = "https://github.com/googleworkspace/cli";
      mainProgram = "gws";
      platforms = lib.attrNames binaryMeta.platforms;
    };
  }
