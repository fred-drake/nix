{pkgs, ...}: {
  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    btop
  ];
}
