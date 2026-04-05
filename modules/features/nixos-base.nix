# NixOS base feature — unconditional system defaults for all NixOS hosts.
# No capability guard needed: timezone and base packages apply everywhere.
_: {
  my.modules.nixos.base = {
    lib,
    pkgs,
    ...
  }: {
    time.timeZone = lib.mkDefault "America/New_York";
    environment.systemPackages = with pkgs; [btop];
  };
}
