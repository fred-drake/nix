{inputs, ...}: _final: prev: {
  # Disable flaky python tests:
  # - uvloop: timing-sensitive tests fail intermittently
  # - openai-whisper: tests/test_audio.py spawns ffmpeg, which gets killed in
  #   the build sandbox while decoding tests/jfk.flac. Tests are gated by
  #   doInstallCheck (not doCheck) so override that.
  python313Packages = prev.python313Packages.override {
    overrides = _python-final: python-prev: {
      uvloop = python-prev.uvloop.overrideAttrs (_: {doCheck = false;});
      openai-whisper = python-prev.openai-whisper.overrideAttrs (_: {doInstallCheck = false;});
    };
  };

  # The top-level pkgs.openai-whisper alias is bound before our python
  # overrides apply, so override it directly too.
  openai-whisper = prev.openai-whisper.overrideAttrs (_: {doInstallCheck = false;});

  # Disable tailscale tests (tsconsensus test times out)
  tailscale = prev.tailscale.overrideAttrs (_: {doCheck = false;});
  inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) wireguard-tools;

  # Pin woodpecker-agent to the rev frozen in flake input
  # nixpkgs-woodpecker-agent so it stays in lockstep with the server
  # image pinned in apps/fetcher/containers.toml. See
  # .claude/skills/woodpecker-upgrade/SKILL.md before bumping.
  inherit (inputs.nixpkgs-woodpecker-agent.legacyPackages.${prev.stdenv.hostPlatform.system}) woodpecker-agent;

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
          sha256 = "sha256-Zj5qATaW1QPTInC/Y/jZx2xq5eHG/OQixpj8DWUpEXY=";
        };
      })
    else prev.spotify;
}
