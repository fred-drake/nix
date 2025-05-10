{config, ...}: let
  blocky = config.soft-secrets.blocky;
in {
  services.blocky = {
    enable = true;
    settings = {
      upstreams = {
        groups = {
          default = [
            "https://dns10.quad9.net/dns-query"
          ];
        };
      };

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
