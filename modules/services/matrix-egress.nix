# Phase 3 — LiveKit Egress (audio-only call recording) for undercity.
#
# Records Element Call audio for AI coaching evaluation. Egress is the ONLY
# container on this otherwise all-native box (Phases 1-2). Architecture:
#   - The native LiveKit SFU (matrix-rtc.nix) dispatches egress jobs over Redis.
#   - This egress worker registers on that Redis and, on request, joins a room
#     as a hidden participant and writes audio-only .ogg via GStreamer (NO
#     headless Chrome -> low RAM; never request room-composite).
#   - Recording is triggered MANUALLY for now (`lk egress start ...`); auto-
#     record via a livekit webhook is a later sub-phase.
#
# Redis: native, loopback-only, no password (single box). The container reaches
# it, the SFU ws (7880) and the UDP media range over --network=host, the same
# loopback trick the SFU uses for media.
#
# Secret: reuses host/undercity/livekit (api_key/api_secret) from Phase 2.
# egress.yaml wants SCALAR api_key/api_secret (not the "key: secret" map the SFU
# and lk-jwt keyfile use), so it's rendered by a dedicated sops template.
#
# No firewall change: everything is loopback; output is a local file.
{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  recordingsDir = "/var/lib/livekit-egress/recordings";
in {
  # Native Redis — egress control channel only. Loopback, no auth.
  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };

  sops = {
    # Same underlying sopsFile/key as matrix-rtc.nix, distinct names so this
    # module is self-contained.
    secrets = {
      egress-livekit-api-key = {
        sopsFile = config.secrets.host.undercity.livekit;
        key = "api_key";
        mode = "0400";
      };
      egress-livekit-api-secret = {
        sopsFile = config.secrets.host.undercity.livekit;
        key = "api_secret";
        mode = "0400";
      };
    };
    # Full egress config rendered with secrets inlined. restartUnits is required:
    # a changed sops template does NOT restart a podman container by itself.
    templates."egress.yaml" = {
      # 0444: world-readable so the container's non-root 'egress' user can read
      # the config (the image rejects root due to PulseAudio). The LiveKit
      # credentials are internal to this single-tenant server.
      mode = "0444";
      restartUnits = ["podman-livekit-egress.service"];
      content = ''
        log_level: info
        api_key: ${config.sops.placeholder.egress-livekit-api-key}
        api_secret: ${config.sops.placeholder.egress-livekit-api-secret}
        ws_url: ws://127.0.0.1:7880
        redis:
          address: 127.0.0.1:6379
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/livekit-egress 0755 root root -"
    # Container runs as egress (uid=1001, gid=0). Mode 0775 gives the root
    # group write access so the container user can create recording files.
    "d ${recordingsDir} 0775 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.livekit-egress = {
      image = containers-sha."docker.io"."livekit/egress"."v1.13.0"."linux/amd64";
      autoStart = true;
      extraOptions = [
        "--network=host"
        # GStreamer scratch space. Audio-only is light, but podman's default
        # 64MB shm is stingy; 256MB is ample headroom (room-composite would
        # need ~1GB, but we never run it).
        "--shm-size=256m"
      ];
      volumes = [
        "${config.sops.templates."egress.yaml".path}:/etc/egress.yaml:ro"
        "${recordingsDir}:/out"
      ];
      environment = {
        EGRESS_CONFIG_FILE = "/etc/egress.yaml";
        TZ = "America/New_York";
      };
    };
  };

  # Egress needs redis (and ideally the SFU) up first.
  systemd.services.podman-livekit-egress = {
    after = ["redis.service" "livekit.service"];
    wants = ["redis.service"];
  };
}
