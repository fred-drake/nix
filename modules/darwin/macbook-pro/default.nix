# Configuration specific to the MacBook Pro device.
_: {
  my.hasWoodpeckerAgent = true;
  my.hasIosSigning = true;

  homebrew = {
    brews = ["container" "steipete/tap/remindctl"];
    casks = ["bartender" "block-buzz" "naps2" "proxy-audio-device" "elgato-stream-deck" "elgato-camera-hub"];
    masApps = {
      "iWallpaper - Live Wallpaper" = 1552826194;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Remap Caps Lock to Control
  };

  # Remove the legacy static mappings on activation. Internal service names are
  # now delivered to connected Tailnet clients through Headscale MagicDNS.
  system.activationScripts.postActivation.text = ''
    temporaryHosts="$(mktemp)"
    trap 'rm -f "$temporaryHosts"' EXIT

    awk '
      $0 == "# BEGIN nix-darwin Hetzner internal services" { in_block = 1; next }
      $0 == "# END nix-darwin Hetzner internal services" { in_block = 0; next }
      !in_block { print }
    ' /etc/hosts > "$temporaryHosts"
    cat "$temporaryHosts" > /etc/hosts
  '';
}
