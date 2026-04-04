{...}: {
  my.modules.nixos.base = {pkgs, ...}: {
    time.timeZone = "America/New_York";
    environment.systemPackages = with pkgs; [btop];
  };
}
