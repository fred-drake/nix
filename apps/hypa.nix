# Hypa CLI (https://github.com/Hypabolic/Hypa) — pre-built binary distribution.
#
# Hypa is a local context runtime for coding agents: it runs shell commands
# through deterministic compression filters before the output reaches the
# agent context window.  It is required by the pi-hypa extension
# (apps/pi-hypa.nix) which resolves the "hypa" binary from PATH at runtime.
#
# The GitHub release tarballs are self-contained: each archive includes the
# hypa executable and its native tree-sitter dylib/so files.  .NET NativeAOT
# loads these native libraries from the same directory as the executable, so
# everything is installed under $out/libexec/hypa/ and $out/bin/hypa is a
# symlink that lets dyld/ld resolve the real executable directory correctly.
#
# Platform support: aarch64-darwin, x86_64-darwin, aarch64-linux, x86_64-linux.
# Windows binaries (.zip) are not packaged here.
#
# Version + hashes come from ./fetcher/hypa.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}: let
  system = stdenvNoCC.hostPlatform.system;

  platformMap = {
    "aarch64-darwin" = "osx-arm64";
    "x86_64-darwin" = "osx-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform =
    platformMap.${system}
    or (throw "hypa: unsupported platform ${system}");

  hash =
    pin.hashes.${system}
    or (throw "hypa: no hash for ${system}");
in
  stdenvNoCC.mkDerivation {
    pname = "hypa";
    inherit (pin) version;

    src = fetchurl {
      url = "https://github.com/Hypabolic/Hypa/releases/download/v${pin.version}/hypa-${platform}.tar.gz";
      inherit hash;
    };

    # The tarball extracts to hypa-<platform>/
    sourceRoot = "hypa-${platform}";

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Install the executable and its native library companions into libexec/hypa/
      # so that .NET NativeAOT can find the dylib/so files via the executable-relative
      # search path (dyld on macOS resolves symlinks to get the real binary directory).
      install -d $out/libexec/hypa
      install -m 0755 hypa $out/libexec/hypa/hypa

      # Copy native tree-sitter libraries and any other runtime-loaded shared libs
      for lib_file in *.dylib *.so; do
        [ -e "$lib_file" ] || continue
        cp "$lib_file" $out/libexec/hypa/
      done

      # Expose hypa on PATH via a symlink (dyld resolves symlinks → real dir → finds dylibs)
      install -d $out/bin
      ln -s ../libexec/hypa/hypa $out/bin/hypa

      runHook postInstall
    '';

    meta = {
      description = "Local context runtime for coding agents: compress shell output, query code, and proxy MCP tools";
      homepage = "https://github.com/Hypabolic/Hypa";
      license = lib.licenses.free; # FSL-1.1-ALv2
      mainProgram = "hypa";
      platforms = lib.attrNames platformMap;
    };
  }
