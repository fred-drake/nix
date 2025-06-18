{
  pkgs,
  lib,
  config,
  ...
}: {
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [neovim git kea];
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        ListenAddress = config.soft-secrets.host.dns1.admin_ip_address;
      };
    };
  };
  networking = {
    hostName = "dns1";
    firewall.enable = false;
    interfaces = {
      "end0" = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            {
              address = config.soft-secrets.host.dns1.admin_ip_address;
              prefixLength = 24;
            }
          ];
        };
      };
      "end0.40" = {
        ipv4 = {
          addresses = [
            {
              address = config.soft-secrets.host.dns1.iot_ip_address;
              prefixLength = 24;
            }
          ];
          routes = [
            # {
            #   address = "0.0.0.0";
            #   prefixLength = 0;
            #   via = config.soft-secrets.networking.gateway.iot;
            # }
            {
              address = "192.168.30.0"; # WORKSTATION VLAN
              prefixLength = 24;
              via = config.soft-secrets.networking.gateway.iot;
            }
            {
              address = "192.168.50.0"; # SERVICES VLAN
              prefixLength = 24;
              via = config.soft-secrets.networking.gateway.iot;
            }
          ];
        };
      };
      "wlan0" = {
        useDHCP = false;
      };
    };
    vlans = {
      "end0.40" = {
        id = 40;
        interface = "end0";
      };
    };
    defaultGateway = {
      address = config.soft-secrets.networking.gateway.admin;
      interface = "end0";
    };
    nameservers = config.soft-secrets.networking.nameservers.public;
  };

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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = ["root" "@wheel"];
  };

  system.stateVersion = "24.11";
}
