{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "gnomeregan";

    # The PSK is stored outside the Nix store in /etc/wireless.env, which was
    # provisioned out-of-band. Later, this can be templated by sops-nix once
    # secrets are wired up.
    wireless = {
      enable = true;
      secretsFile = "/etc/wireless.env";
      networks."Frecklepie".pskRaw = "ext:HOME_PSK";
    };
    networkmanager.enable = false;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  networking.firewall.allowedTCPPorts = [8084];

  users.users.fdrake = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Where sops-nix will look for the host's age identity. The key is copied
  # over out-of-band before the first deploy that consumes a secret; until
  # then no sops.secrets are declared so this path is unused.
  sops.age.sshKeyPaths = ["/home/fdrake/.ssh/id_infrastructure"];

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    rsync
  ];

  system.stateVersion = "25.11";
}
