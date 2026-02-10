{pkgs, ...}: let
  systemPackages = with pkgs; [vim htop curl wget rsync];
in {
  environment.systemPackages = systemPackages;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
    };
  };

  networking.networkmanager.enable = false;
  networking.useDHCP = false;
}
