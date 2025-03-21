{
  pkgs,
  lib,
  config,
  secrets,
  ...
}: {
  imports = [
    ../../../apps/adguard.nix
  ];

  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.cloudflare-api-key = {
    sopsFile = config.secrets.cloudflare.letsencrypt-token;
    mode = "0400";
    key = "data";
  };

  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        email = config.soft-secrets.acme.email;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare-api-key.path;
      };
      certs = {
        "adguard2.internal.freddrake.com" = {
          domain = "adguard2.internal.freddrake.com";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          webroot = null;
          listenHTTP = null;
          s3Bucket = null;
          environmentFile = config.sops.secrets.cloudflare-api-key.path;
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [neovim git kea];
  services = {
    adguardhome = {
      settings.dns.bind_hosts = ["192.168.40.6"];
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        ListenAddress = "192.168.208.9";
      };
    };
    nginx = {
      enable = true;
      # recommendedGzipSettings = true;
      # recommendedOptimisation = true;
      # recommendedProxySettings = true;
      # recommendedTlsSettings = true;
      virtualHosts = {
        "adguard2.internal.freddrake.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:2500";
            proxyWebsockets = true;
            extraConfig = ''
              # Increase the maximum size of the hash table
              proxy_headers_hash_max_size 1024;

              # Increase the bucket size of the hash table
              proxy_headers_hash_bucket_size 128;

              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };
  };
  networking.hostName = "adguard2";
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
    interfaces."end0" = {
      useDHCP = false;
      ipv4 = {
        addresses = [
          {
            address = "192.168.208.9";
            prefixLength = 24;
          }
        ];
      };
    };

    vlans = {
      "end0.40" = {
        id = 40;
        interface = "end0";
      };
    };

    interfaces."end0.40".ipv4.addresses = [
      {
        address = "192.168.40.6";
        prefixLength = 24;
      }
    ];

    interfaces."end0.40".ipv4.routes = [
      {
        address = "0.0.0.0";
        prefixLength = 0;
        via = "192.168.40.1";
      }
    ];

    defaultGateway = {
      address = "192.168.208.1";
      interface = "end0";
    };

    interfaces."wlan0".useDHCP = false;

    nameservers = ["8.8.8.8" "8.8.4.4"];
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
