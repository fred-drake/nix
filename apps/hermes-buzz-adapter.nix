{
  lib,
  pkgs,
  python3,
  stdenvNoCC,
}: let
  sources = import ./fetcher/repos-src.nix {inherit pkgs;};
  src = sources."hermes-agent-v2026.8.3-src";
in
  stdenvNoCC.mkDerivation {
    pname = "hermes-buzz-adapter";
    version = "2026.8.3-owner-dm";
    inherit src;

    patches = [./hermes-buzz-owner-dm.patch];
    nativeBuildInputs = [python3];
    strictDeps = true;
    dontConfigure = true;

    prePatch = ''
      echo "8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b  plugins/platforms/buzz/adapter.py" \
        | sha256sum -c -
    '';

    buildPhase = ''
      runHook preBuild
      python3 -m py_compile plugins/platforms/buzz/adapter.py
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm0444 plugins/platforms/buzz/adapter.py "$out/adapter.py"
      test "$(find "$out" -type f | wc -l)" -eq 1
      runHook postInstall
    '';

    meta = {
      description = "Hermes v2026.8.3 Buzz adapter with authoritative owner-DM classification";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
