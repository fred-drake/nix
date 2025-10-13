{
  config,
  pkgs,
  lib,
  ...
}: let
  epsonscan2-custom = pkgs.epsonscan2.override {
    withNonFreePlugins = true;
    withGui = false;
  };
in {
  # Allow unfree packages for scanner drivers
  nixpkgs.config.allowUnfree = true;

  # Scanner configuration
  environment.systemPackages = [
    epsonscan2-custom
    pkgs.usbutils # for lsusb debugging
  ];

  # Enable scanner support
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [epsonscan2-custom];

  # Add user to scanner group
  users.users.default.extraGroups = ["scanner"];

  # Create scans directory
  systemd.tmpfiles.rules = [
    "d /home/default/scans 0755 default users -"
  ];
}
