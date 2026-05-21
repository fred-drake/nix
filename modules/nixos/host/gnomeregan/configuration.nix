{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "gnomeregan";

    # PSK comes from a sops-nix secret deployed with wpa_supplicant ownership.
    # Unstable's wpa_supplicant unit drops privileges and runs in a tight
    # namespace, so the file must be readable by the wpa_supplicant user.
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wireless-env.path;
      networks."Frecklepie".pskRaw = "ext:HOME_PSK";
    };
    networkmanager.enable = false;
  };

  sops.secrets.wireless-env = {
    sopsFile = config.secrets.host.gnomeregan.wireless-env;
    key = "data";
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
    mode = "0400";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  fileSystems."/mnt/hetzner-backup" = {
    device = "/dev/disk/by-uuid/d5fb9fae-5cbc-4e37-baa1-ad3603b3dbc0";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };

  networking.firewall.allowedTCPPorts = [8084];

  users.users.fdrake = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    linger = true; # Start systemd user services before fdrake logs in (process-daily, archive-email)
    # Fish as login shell — home-manager handles the actual fish config.
    # ignoreShellProgramCheck avoids the fish 4.5.0 completion generator
    # issue triggered by programs.fish.enable.
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
  };

  environment.shells = [pkgs.fish];

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

  # uvx (used by archive-email's workspace-mcp) downloads pre-built CPython
  # tarballs that are dynamically linked against a generic glibc. NixOS has
  # no /lib64/ld-linux-x86-64.so.2, so those binaries fail with exit 127.
  # nix-ld provides a stub dynamic linker that resolves the path at runtime.
  programs.nix-ld.enable = true;

  system.stateVersion = "25.11";
}
