{inputs, ...}: _final: prev: {
  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

  # WORKAROUND(presenterm): cargo-setup-hook's cargoUseSystemLibs exports
  # RUSTONIG_SYSTEM_LIBONIG=1, requiring pkg-config and oniguruma which
  # upstream presenterm/package.nix has not yet declared. Remove once
  # upstream nixpkgs adds pkg-config and oniguruma to presenterm.
  presenterm = prev.presenterm.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.pkg-config];
    buildInputs = (old.buildInputs or []) ++ [prev.oniguruma];
  });

  spotify =
    if prev.stdenv.hostPlatform.isDarwin
    then
      prev.spotify.overrideAttrs (_: {
        src = prev.fetchurl {
          url = "https://download.scdn.co/SpotifyARM64.dmg";
          sha256 = "sha256-iFLqFQXKPkeCHfzB6hshbZDWjumKN2u4Bj7lvl8waUY=";
        };
      })
    else prev.spotify;
}
