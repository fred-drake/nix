{
  lib,
  stdenv,
  fetchurl,
}: let
  binaryMeta = import ./fetcher/herdr-core-binary.nix;

  platformMap = {
    "x86_64-linux" = "linux-x86_64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "macos-x86_64";
    "aarch64-darwin" = "macos-aarch64";
  };

  platform =
    platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformMeta = binaryMeta.platforms.${platform};
in
  stdenv.mkDerivation {
    pname = "herdr-core";
    inherit (binaryMeta) version;

    src = fetchurl {
      inherit (platformMeta) url hash;
    };

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 herdr-core $out/bin/herdr-core
      ln -s herdr-core $out/bin/hc
      runHook postInstall
    '';

    meta = {
      description = "Herdr Core daemon and CLI (herdr-core / hc)";
      homepage = "https://herdr.dev";
      mainProgram = "herdr-core";
      platforms = lib.attrNames platformMap;
    };
  }
