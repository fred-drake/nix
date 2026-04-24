# Shared options module providing config.my.* for host metadata.
# Injected into NixOS, Darwin, and Home Manager module systems so that
# deferred modules can self-guard with mkIf config.my.hasDesktop etc.
# Single source of truth — imported by nixos-infra.nix, darwin-infra.nix,
# and mk-home-manager.nix.
#
# Usage in feature modules:
#   lib.mkIf config.my.hasDesktop { ... }     # desktop environments
#   lib.mkIf config.my.hasHyprland { ... }    # hyprland-specific
#   lib.mkIf config.my.isWorkstation { ... }  # full workstation apps
#   lib.mkIf config.my.hasNvidia { ... }      # NVIDIA GPU
{lib, ...}: {
  options.my = {
    # Identity
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the current system being configured.";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "fdrake";
      description = "The primary user account name.";
    };

    # Capability flags — features guard on these, not hostname strings
    isWorkstation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Full workstation with heavy apps (discord, slack, spotify, etc).";
    };
    isServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Server host (headscale, ironforge, orgrimmar, anton).";
    };
    hasMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Prometheus node exporter for monitoring.";
    };
    hasDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Has a graphical desktop environment (Hyprland, GNOME, etc).";
    };
    hasHyprland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Uses the Hyprland window manager.";
    };
    hasGnome = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Uses the GNOME desktop environment.";
    };
    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Has NVIDIA GPU (driver + CUDA support).";
    };
    hasGaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Gaming support (Steam, gamescope, gamemode).";
    };
    hasGpuPassthrough = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "GPU passthrough with VFIO/libvirtd for Windows VM.";
    };
    hasPipewire = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Pipewire audio stack.";
    };
    hasWoodpeckerAgent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run a Woodpecker CI agent as a user launchd service (macOS iOS builds).";
    };
    hasAutoGc = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatic Nix garbage collection (angrr on NixOS; nix.gc on Darwin).";
    };
  };
}
