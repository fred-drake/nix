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
    ../../../secrets/gitea-runner-2.nix
  ];

  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  boot.isContainer = true;

  # Supress systemd units that don't work because of LXC.
  # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        ListenAddress = config.soft-secrets.host.gitea-runner-2.admin_ip_address;
      };
    };
  };
  networking.hostName = "gitea-runner-2";
  users.groups.podman = {
    name = "podman";
  };

  users.users.default = {
    isNormalUser = true;
    password = "";
    extraGroups = ["wheel" "podman"];
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
            address = config.soft-secrets.host.gitea-runner-2.admin_ip_address;
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
          address = config.soft-secrets.host.gitea-runner-2.service_ip_address;
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

  system.stateVersion = "24.11";
}
