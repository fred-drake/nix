{config, ...}: let
  inherit (config.soft-secrets) blocky;
in {
  services.blocky = {
    enable = true;
    settings = {
      upstreams = {
        timeout = "1s";
        groups = {
          default = [
            # "https://dns10.quad9.net/dns-query"
            "8.8.8.8" # Google DNS 1
            "8.8.4.4" # Google DNS 2
            "1.1.1.1" # Cloudflare DNS
            "74.40.74.40" # Frontier DNS 1
            "74.40.74.41" # Frontier DNS 2
          ];
        };
      };

      # Add conditional mapping for different networks
      # conditional = {
      #   mapping = {
      #     "192.168.30.0/24" = "default";
      #     "192.168.40.0/24" = "default";
      #     "192.168.50.0/24" = "default";
      #     "192.168.208.0/24" = "default";
      #   };
      # };

      blocking = {
        blackLists = {
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
          ];
        };
        whiteLists = {
          ads = [];
        };
        clientGroupsBlock = {
          default = ["ads"];
          # "192.168.50.5" = []; # Exclude this IP from all blocklists
        };
        blockType = "zeroIp";
      };

      customDNS = {
        customTTL = "1h";
        mapping = blocky.custom-dns-mapping;
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };
}
