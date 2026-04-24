# Automatic Nix garbage collection for Darwin hosts.
# Darwin has no angrr equivalent — we rely on nix.gc to clean up store
# paths and nix.optimise to hard-link duplicates on its own timer.
_: {
  my.modules.darwin.auto-gc = {
    config,
    lib,
    ...
  }:
    lib.mkIf config.my.hasAutoGc {
      nix.gc = {
        automatic = true;
        # Daily at 04:30 — omitting Weekday makes launchd fire every day.
        # Was weekly Tuesday in the old nix-daemon.nix before this migration.
        interval = [
          {
            Hour = 4;
            Minute = 30;
          }
        ];
        options = "--delete-older-than 14d";
      };
      nix.optimise.automatic = true;
    };
}
