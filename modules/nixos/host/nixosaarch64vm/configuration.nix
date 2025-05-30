{
  modulesPath,
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  networking = {
    hostName = "nixosaarch64vm";
    interfaces."ens160" = {
      useDHCP = false;
      ipv4 = {
        addresses = [
          {
            address = config.soft-secrets.host.nixosaarch64vm.workstation_ip_address;
            prefixLength = 24;
          }
        ];
      };
    };
    extraHosts = ''
      192.168.50.26 dev.brainrush.ai
      ${soft-secrets.host.gitea.service_ip_address} gitea.${soft-secrets.networking.domain}
    '';

    defaultGateway = {
      address = config.soft-secrets.networking.gateway.workstation;
      interface = "ens160";
    };

    nameservers = config.soft-secrets.networking.nameservers.internal;
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.fdrake = {
    isNormalUser = true;
    home = "/home/fdrake";
    description = "Fred Drake";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
    packages = with pkgs; [direnv git just];
    shell = pkgs.zsh;
  };
  users.users.armbuilder = {
    isNormalUser = true;
    password = "";
    extraGroups = ["podman"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEIsIHbFPUHkWboet8BkVRMo2i0ttbEVqn7Yck3CkFf+" # Armbuilder key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4" # Fdrake user key
    ];
  };
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  system.stateVersion = "24.11";
}
