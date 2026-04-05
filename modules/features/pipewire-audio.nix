# Pipewire audio feature — contributes to NixOS via deferredModules.
# Applies to hosts with my.hasPipewire = true.
_: {
  my.modules.nixos.pipewire = {
    config,
    lib,
    ...
  }:
    lib.mkIf config.my.hasPipewire {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      services.pulseaudio.enable = false;

      # rtkit is recommended for pipewire real-time scheduling
      security.rtkit.enable = true;
    };
}
