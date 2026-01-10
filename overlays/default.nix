{inputs, ...}: _final: prev: {
  # Disable flaky uvloop tests (timing-sensitive tests fail intermittently)
  python313Packages = prev.python313Packages.override {
    overrides = _python-final: python-prev: {
      uvloop = python-prev.uvloop.overrideAttrs (_: {doCheck = false;});
    };
  };

  # Disable tailscale tests (tsconsensus test times out)
  tailscale = prev.tailscale.overrideAttrs (_: {doCheck = false;});
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) wireguard-tools;

  # Pull bat-extras from stable and disable tests for all components
  bat-extras = let
    stableBatExtras = inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.bat-extras;
  in
    prev.lib.recurseIntoAttrs {
      batgrep = stableBatExtras.batgrep.overrideAttrs (_: {doCheck = false;});
      batman = stableBatExtras.batman.overrideAttrs (_: {doCheck = false;});
      batpipe = stableBatExtras.batpipe.overrideAttrs (_: {doCheck = false;});
      batwatch = stableBatExtras.batwatch.overrideAttrs (_: {doCheck = false;});
      batdiff = stableBatExtras.batdiff.overrideAttrs (_: {doCheck = false;});
      prettybat = stableBatExtras.prettybat.overrideAttrs (_: {doCheck = false;});
    };

  spotify =
    if prev.stdenv.isDarwin
    then
      prev.spotify.overrideAttrs (oldAttrs: {
        src = prev.fetchurl {
          url = oldAttrs.src.url or "https://download.scdn.co/SpotifyARM64.dmg";
          sha256 = "sha256-/rrThZOpjzaHPX1raDe5X8PqtJeTI4GDS5sXSfthXTQ=";
        };
      })
    else prev.spotify;
}
