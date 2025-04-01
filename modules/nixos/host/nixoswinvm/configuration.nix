{
  inputs,
  modulesPath,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  # REQUIRED - see: https://github.com/nixos/nixpkgs/issues/9899
  boot.initrd.kernelModules = ["hv_vmbus" "hv_storvsc"];

  # RECOMMENDED
  # - use 800x600 resolution for text console, to make it easy to fit on screen
  boot.kernelParams = ["video=hyperv_fb:800x600"]; # https://askubuntu.com/a/399960
  # - avoid a problem with `nix-env -i` running out of memory
  boot.kernel.sysctl."vm.overcommit_memory" = "1"; # https://github.com/NixOS/nix/issues/421

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
    hostName = "nixoswinvm";
    # domain = "internal.freddrake.com";
    # dhcpcd.enable = false;
    # interfaces.ens18.
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
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
  ];

  system.stateVersion = "24.05";
}
