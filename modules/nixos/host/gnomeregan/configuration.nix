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

  # Disable systemd-in-initrd so the NixOS setupSecrets activation script
  # runs in stage 2 (after /home mounts) rather than stage 1. sops-nix
  # needs the age key at /home/fdrake/.ssh/id_infrastructure, which isn't
  # accessible during stage 1; running there causes setupSecrets to abort
  # on the first undecryptable workstation secret (e.g. calibre-storage)
  # and leaves /run/secrets/* unwritten, which then breaks any service
  # bind-mounting from /run/secrets/.
  boot.initrd.systemd.enable = false;

  networking = {
    hostName = "gnomeregan";

    # PSK comes from a sops-nix secret deployed with wpa_supplicant
    # ownership. Now that NixOS-level sops decryption works reliably at
    # stage 2 activation (see sops.age.sshKeyPaths below), the secret is
    # written to /run/secrets/wireless-env before systemd starts
    # wpa_supplicant.service.
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wireless-env.path;
      networks."Frecklepie".pskRaw = "ext:HOME_PSK";
    };
    networkmanager.enable = false;
  };

  sops.secrets.wireless-env = {
    sopsFile = config.secrets.host.gnomeregan.wireless-env;
    format = "yaml";
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

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
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

  # sops-nix prefers /etc/ssh/ssh_host_ed25519_key — gnomeregan's host
  # SSH key, registered as an age recipient in nix-secrets/.sops.yaml.
  # Lives on /, so it's accessible in stage 1; required for the upcoming
  # NixOS 26.11 removal of scripted initrd. /root/id_infrastructure is
  # kept temporarily as a fallback during this migration; drop it once
  # we've confirmed the host-key path decrypts every required secret.
  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/root/id_infrastructure"
  ];

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
