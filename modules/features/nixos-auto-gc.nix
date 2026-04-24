# Automatic Nix garbage collection for NixOS hosts.
# Combines angrr (prunes stale GC roots) with nix.gc (deletes unreferenced
# store paths) and nix.optimise (weekly hard-linking of duplicate files).
# angrr.service runs Before=nix-gc.service via enableNixGcIntegration,
# which auto-enables whenever nix.gc.automatic = true.
{inputs, ...}: {
  my.modules.nixos.auto-gc = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # imports is outside the mkIf guard by necessity — NixOS modules can't
    # conditionally import. angrr's option definitions load on every host,
    # but services.angrr.enable below stays false unless hasAutoGc is true.
    imports = [inputs.angrr.nixosModules.angrr];
    # config = wrapper required because we have a top-level imports; can't
    # combine bare `lib.mkIf { ... }` with imports at the module root.
    config = lib.mkIf config.my.hasAutoGc {
      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
        # Spread GC start across a 45min window so fleet hosts don't all
        # fire at the same wall-clock instant.
        randomizedDelaySec = "45min";
      };
      nix.optimise = {
        automatic = true;
        dates = ["weekly"];
      };

      services.angrr = {
        enable = true;
        # Source the package from angrr's own flake output rather than
        # pkgs.angrr. nixpkgs-stable (used by Hetzner servers) does not ship
        # an `angrr` attribute; nixpkgs-unstable does. Routing through the
        # flake packages works uniformly across every host.
        package = inputs.angrr.packages.${pkgs.stdenv.hostPlatform.system}.default;
        # Preset: populates temporary-root-policies (.direnv, result*) and
        # profile-policies (both system and user profiles) with keep-since =
        # this period. User profile inclusion means home-manager generations
        # older than 14d are pruned too — intentional for uniform retention.
        period = "14d";
        # Add a safety floor: always keep the 3 newest system generations,
        # regardless of age. The preset itself has no keep-latest-n.
        settings.profile-policies.system.keep-latest-n = 3;
      };
    };
  };
}
