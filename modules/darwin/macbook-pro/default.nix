# Configuration specific to the MacBook Pro device.
_: {
  my.hasWoodpeckerAgent = true;
  my.hasIosSigning = true;

  homebrew = {
    brews = ["container" "steipete/tap/remindctl"];
    casks = ["bartender" "mutedeck" "naps2" "proxy-audio-device" "elgato-stream-deck" "elgato-camera-hub"];
    masApps = {
      "iWallpaper - Live Wallpaper" = 1552826194;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };

  # Keep Hetzner web endpoints reachable while the home DNS resolver is offline.
  # These are private Hetzner addresses reached through headscale's advertised
  # 10.1.0.0/16 subnet route; the application hosts do not have direct Tailnet
  # addresses of their own.
  # nix-darwin deliberately leaves /etc/hosts unmanaged. Maintain only this
  # marked block so macOS's standard entries remain intact.
  system.activationScripts.postActivation.text = ''
    temporaryHosts="$(mktemp)"
    trap 'rm -f "$temporaryHosts"' EXIT

    awk '
      $0 == "# BEGIN nix-darwin Hetzner internal services" { in_block = 1; next }
      $0 == "# END nix-darwin Hetzner internal services" { in_block = 0; next }
      !in_block { print }
    ' /etc/hosts > "$temporaryHosts"

    cat >> "$temporaryHosts" <<'EOF'
    # BEGIN nix-darwin Hetzner internal services
    10.1.1.2 headscale.internal.freddrake.com
    10.1.1.3 jellyfin.internal.freddrake.com seerr.internal.freddrake.com jellyseerr.internal.freddrake.com sonarr.internal.freddrake.com radarr.internal.freddrake.com lidarr.internal.freddrake.com prowlarr.internal.freddrake.com sabnzbd.internal.freddrake.com bazarr.internal.freddrake.com
    10.1.1.4 gitea.internal.freddrake.com gitea-status.internal.freddrake.com woodpecker.internal.freddrake.com paperless.internal.freddrake.com paperless-ai.internal.freddrake.com resume.internal.freddrake.com calibre-web.internal.freddrake.com files.internal.freddrake.com
    10.1.1.5 traceway.internal.freddrake.com gatus.internal.freddrake.com
    # END nix-darwin Hetzner internal services
    EOF

    cat "$temporaryHosts" > /etc/hosts
  '';
}
