{inputs, ...}: final: prev:
(import ./glance.nix {inherit inputs;} final prev)
// {
  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

  # WORKAROUND(podman): nixpkgs b5aa0fbd restricted podman to linux-only in meta.platforms
  # despite having Darwin build code; remove when nixpkgs restores aarch64-darwin to podman.meta.platforms.
  podman = prev.podman.overrideAttrs (old: {
    meta =
      old.meta
      // {
        platforms = old.meta.platforms ++ ["aarch64-darwin" "x86_64-darwin"];
      };
  });

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
