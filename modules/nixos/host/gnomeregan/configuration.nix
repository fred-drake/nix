{pkgs, ...}: {
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

    # PSK stored out-of-band in /etc/wireless.env (provisioned manually).
    # Unstable's wpa_supplicant unit drops to the wpa_supplicant user and
    # runs in a tight namespace, so the file must be readable by that user;
    # the tmpfiles rule below enforces ownership on every boot.
    wireless = {
      enable = true;
      secretsFile = "/etc/wireless.env";
      networks."Frecklepie".pskRaw = "ext:HOME_PSK";
    };
    networkmanager.enable = false;
  };

  systemd.tmpfiles.rules = [
    "z /etc/wireless.env 0640 wpa_supplicant wpa_supplicant -"
  ];

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

  # sops-nix uses this age identity to decrypt NixOS-level secrets at
  # activation time. Lives at /root/ (on /) so it's available before
  # home-manager's sops runs; the HM secrets feature owns
  # /home/fdrake/.ssh/id_infrastructure (as a symlink to a HM-sops-
  # decrypted target that doesn't exist until HM activates), so that
  # path can't be used for NixOS-level decryption. Placed manually with
  #   sudo cp /home/fdrake/.config/sops-nix/secrets/ssh-id-infrastructure /root/id_infrastructure
  #   sudo chmod 600 /root/id_infrastructure
  sops.age.sshKeyPaths = ["/root/id_infrastructure"];

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
