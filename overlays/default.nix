{inputs, ...}: _final: prev: {
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.system}) wireguard-tools;

  spotify = prev.spotify.overrideAttrs (oldAttrs: {
    src = prev.fetchurl {
      url = oldAttrs.src.url or "https://download.scdn.co/SpotifyARM64.dmg";
      sha256 = "sha256-fTyACxbyIgg7EwIgnNvNerJGUwAVLP2bg0TMnOegWeQ=";
    };
  });
}
