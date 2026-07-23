{inputs, ...}: final: prev:
(import ./glance.nix {inherit inputs;} final prev)
// {
  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

  spotify =
    if prev.stdenv.isDarwin
    then
      prev.spotify.overrideAttrs (_: {
        src = prev.fetchurl {
          url = "https://download.scdn.co/SpotifyARM64.dmg";
          sha256 = "sha256-vtAD7Jz4AQqTbAd0YtsS9aeBr1ES0YegLwB7A8XFKJc=";
        };
      })
    else prev.spotify;
}
