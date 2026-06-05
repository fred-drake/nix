{inputs, ...}: final: prev:
(import ./glance.nix {inherit inputs;} final prev)
// {
  # WORKAROUND(uvloop): timing-sensitive tests flake in the sandbox; remove
  #   doCheck override when upstream stabilizes them.
  # WORKAROUND(openai-whisper): tests/test_audio.py spawns ffmpeg, killed in
  #   the build sandbox while decoding tests/jfk.flac; gated by doInstallCheck
  #   (not doCheck). Remove when the test no longer needs ffmpeg in-sandbox.
  python313Packages = prev.python313Packages.override {
    overrides = _python-final: python-prev: {
      uvloop = python-prev.uvloop.overrideAttrs (_: {doCheck = false;});
      openai-whisper = python-prev.openai-whisper.overrideAttrs (_: {doInstallCheck = false;});
    };
  };

  # The top-level pkgs.openai-whisper alias is bound before our python
  # overrides apply, so override it directly too. See WORKAROUND(openai-whisper)
  # above.
  openai-whisper = prev.openai-whisper.overrideAttrs (_: {doInstallCheck = false;});

  # WORKAROUND(tailscale): tsconsensus test times out; remove doCheck override
  #   when the upstream test is fixed.
  tailscale = prev.tailscale.overrideAttrs (_: {doCheck = false;});
  # WORKAROUND(wireguard-tools): pinned from stable. Reason undocumented — most
  #   likely a past unstable breakage; re-test unstable and drop the pin if it
  #   builds/works there.
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) wireguard-tools;

  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

  # WORKAROUND(bat-extras): pulled from stable + tests disabled because the
  #   unstable build/tests break; re-test unstable and remove when it builds
  #   clean there.
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
          sha256 = "sha256-m7Wbcl1ewIa92n/eCTgF62EN63KJyWPRW2ZF71/8btk=";
        };
      })
    else prev.spotify;
}
