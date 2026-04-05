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
