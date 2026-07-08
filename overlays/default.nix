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
      prev.spotify.overrideAttrs (oldAttrs: {
        src = prev.fetchurl {
          url = oldAttrs.src.url or "https://download.scdn.co/SpotifyARM64.dmg";
          sha256 = "sha256-rQuvF7LWHBR3q8GJQWO671n1NRDKinQps+zYfXPktrU=";
        };
      })
    else prev.spotify;
}
