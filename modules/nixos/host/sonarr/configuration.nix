{
  pkgs,
  modulesPath,
  lib,
  config,
  ...
}: {
  imports = [
    # Include the default lxc/lxd configuration.
    # "${modulesPath}/virtualisation/lxc-container.nix"
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    ../../../secrets/cloudflare.nix
  ];

  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  boot = {
    isContainer = true;
    kernelModules = ["nfs"];
    supportedFilesystems = ["nfs"];
  };
  # boot.initrd = {
  #   supportedFilesystems = ["nfs"];
  #   kernelModules = ["nfs"];
  # };

  # Supress systemd units that don't work because of LXC.
  # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
    nfs-utils # NFS client utilities
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        ListenAddress = config.soft-secrets.host.sonarr.admin_ip_address;
      };
    };
    # NFS client configuration
    rpcbind.enable = true;
    nfs.server.enable = false;
  };

  # Configure NFS mounts with simpler options
  fileSystems = {
    "/mnt/sabnzbd_downloads" = {
      device = "192.168.50.51:/sabnzbd_downloads";
      fsType = "nfs";
      options = [
        "defaults"
        "nfsvers=4"
        "_netdev"
      ];
    };

    "/mnt/videos" = {
      device = "${config.soft-secrets.host.nas-nfs.service_ip_address}:/videos";
      fsType = "nfs";
      options = [
        "defaults"
        "nfsvers=4"
        "_netdev"
      ];
    };
  };

  networking.hostName = "sonarr";
  users.users.default = {
    isNormalUser = true;
    password = "";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgXFo9rrjL9BXyuIeji6VcEBMeONo9siz5xEgG3pCRwdb9cg6YJ14MYrVQG3uP7W0qM4TlqdpE4NQnoshD006vLLTYja13tIXxbjFcwTzDnNu0mtcJh+vBJ6kZNK0kNk7e6NaGip4swU1dOS65dQ7BQGj1DjdIhahgae6ECMgQd3H6D+YVoMvgSjQgsOqhwfrJIXIMGLv2SjXclMy/atSHUKNYdPxZAX/Cn0pY2wa31HxM2HNydKMUhiSj/twALn7Vzbl1QLEoY8QFL8QhsnTP3BMQfHwzhIIYwficpoF23yuxMa+cDfTqfF5LkK1iRiIn56lFJgna8nYIPvp5BMReIypPeLw+7sB384HHeBwTguuR9ojQ4W3gZvRipn5wvwvivqnQPE3Stcq8aYmIrSNf7pRP7SpsxLqfBvKA/RmI4ZqmXNnK0frEj9CQNpTOpKE/ESL0qCqV58uK6uGS/xo+U4sRjR2nSPGUFT5dmOaCxvcZMgeNCBdrTwouYEvgIOjVOYBd6Z2r5L1fk2u2zWGmzuLi1aXfXtJrZur1A/t0Ak7trHY1w0iLn3KH/qW+vqSVYKr5fyjHFp2lQiPk3hyPn7aUQhkes9WO2JNCWhTyGv+lV5OaTW+isJ9Ct6AYMOFmzvIJzLhXYP45A0EHCYexdXJo9CZ+MYvrNOmdziV5fw=="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7sjvSwPCcdgBGhTXz0hpTkZX5PaaLrQMrNob2Eb+BYvQsYZIWFmnecx7sIClaDsSV48QwvXvLGcR7RUwkpRnsH09nabZiz6zMqn4Ice+fU7ZvexPqcwOvc/8nQmDwi9lJ/58UBgkls1gTSbcAESejomVB3CbX9PaiENTQcWcKe24/1US6/0BZk9AHoD5HFBP8oDKFi2TeLHqme2LQhnZ/Rrdr6AdeQe4VutHHPEFnsBRk/ZzLjPIsJX1LxA/0bbkX1sLCzNe6jtOiw5RfH4e2uOoRNypEPJkt7dQclfUy/iNI7vzQod83BE6TCr3d6KF/eur1utP+V9FRRSzUlFL1"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  networking = {
    firewall.enable = false;
    interfaces."eth0" = {
      useDHCP = false;
      ipv4 = {
        addresses = [
          {
            address = config.soft-secrets.host.sonarr.admin_ip_address;
            prefixLength = 24;
          }
        ];
      };
    };

    vlans = {
      "eth0.50" = {
        id = 50;
        interface = "eth0";
      };
    };

    interfaces."eth0.50".ipv4 = {
      addresses = [
        {
          address = config.soft-secrets.host.sonarr.service_ip_address;
          prefixLength = 24;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = config.soft-secrets.networking.gateway.service;
        }
      ];
    };

    defaultGateway = {
      address = config.soft-secrets.networking.gateway.admin;
      interface = "eth0";
    };

    nameservers = config.soft-secrets.networking.nameservers.internal;
  };

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = ["root" "@wheel"];
  };

  # Ensure all required systemd services are enabled
  systemd = {
    services = {
      network-online.enable = true;
      NetworkManager-wait-online.enable = true;
    };
    # Add mount dependencies
    mounts = [
      {
        what = "${config.soft-secrets.host.nas-nfs.service_ip_address}:/sabnzbd_downloads";
        where = "/mnt/sabnzbd_downloads";
        type = "nfs";
        wants = ["network-online.target"];
        after = ["network-online.target"];
      }
      {
        what = "${config.soft-secrets.host.nas-nfs.service_ip_address}:/videos";
        where = "/mnt/videos";
        type = "nfs";
        wants = ["network-online.target"];
        after = ["network-online.target"];
      }
    ];
    tmpfiles.rules = [
      "d /mnt/sabnzbd_downloads 0755 root root -"
      "d /mnt/videos 0755 root root -"
    ];
  };

  system.stateVersion = "24.11";
}
