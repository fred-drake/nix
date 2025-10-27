{inputs, ...}: _final: prev: {
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.system}) wireguard-tools;

  # Pull bat-extras from stable and disable tests for all components
  bat-extras = let
    stableBatExtras = inputs.nixpkgs-stable.legacyPackages.${prev.system}.bat-extras;
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
          sha256 = "sha256-0gwoptqLBJBM0qJQ+dGAZdCD6WXzDJEs0BfOxz7f2nQ=";
        };
      })
    else prev.spotify;
}
