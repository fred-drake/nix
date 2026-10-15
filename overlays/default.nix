{inputs, ...}: _final: prev: {
  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

  # WORKAROUND(atuin): e2e_capture PTY tests time out under macOS sandboxing on Darwin.
  # Tracked upstream in Nixpkgs issue #573527 ("Build failure: atuin" on aarch64-darwin).
  # Remove this override once upstream nixpkgs adds Darwin checkFlags / skips the flaky test.
  atuin = prev.atuin.overrideAttrs {
    doCheck = false;
  };

  typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
    pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
      outputHash = "sha256-PmyJb8090pEPc09Tbv8RgdvQpzpba2L8ve87+aVncQU=";
    });
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
