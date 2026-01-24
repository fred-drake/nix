{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  bun,
  makeWrapper,
  glibc,
}: let
  binaryMeta = import ../fetcher/claude-code-binary.nix;

  # Map Nix platform to Claude Code platform names
  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  platformMeta = binaryMeta.platforms.${platform};
in
  stdenv.mkDerivation {
    pname = "claude-code";
    inherit (binaryMeta) version;

    src = fetchurl {
      url = "${binaryMeta.baseUrl}/${binaryMeta.version}/${platform}/claude";
      inherit (platformMeta) hash;
    };

    nativeBuildInputs = [makeWrapper] ++ lib.optionals stdenv.isLinux [patchelf];

    buildInputs = [bun];

    # No unpacking needed - it's a single binary
    dontUnpack = true;
    dontBuild = true;
    # Don't strip - it breaks Bun single-file executables
    dontStrip = true;
    # Don't run fixup hooks that might modify the binary
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/.claude-unwrapped
      ${lib.optionalString stdenv.isLinux ''
        # Patch only the interpreter, preserving the rest of the binary
        patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 $out/bin/.claude-unwrapped
      ''}
      makeWrapper $out/bin/.claude-unwrapped $out/bin/claude \
        --prefix PATH : ${lib.makeBinPath [bun]}
      runHook postInstall
    '';

    meta = {
      description = "Claude Code CLI tool";
      homepage = "https://www.anthropic.com/claude-code";
      mainProgram = "claude";
      platforms = lib.attrNames platformMap;
    };
  }
