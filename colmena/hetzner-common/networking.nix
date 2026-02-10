# Network configuration template for Hetzner servers
# Import this and override the IP address in your host config
{
  lib,
  config,
  ...
}: let
  serverType = config.networking.serverType or "normal";
  gatewayAddress =
    if serverType == "gateway"
    then "172.31.1.1"
    else "10.0.0.1";
  isGateway = serverType == "gateway";
in {
  options.networking.serverType = lib.mkOption {
    type = lib.types.enum ["normal" "gateway"];
    default = "normal";
    description = "Type of server networking configuration";
  };

  config = {
    # Disable wait-online service to prevent deployment failures
    # The network is functional (routable/online) but systemd-networkd
    # never considers the interface fully "configured" due to IPv6 issues
    systemd.network.wait-online.enable = false;

    networking = {
      nameservers = [
        "8.8.8.8"
      ];
      defaultGateway = gatewayAddress;
      dhcpcd.enable = false;
      usePredictableInterfaceNames = lib.mkForce true;
      interfaces = lib.mkMerge [
        {
          enp7s0 = {
            ipv4.routes =
              if isGateway
              then []
              else [
                {
                  address = gatewayAddress;
                  prefixLength = 32;
                }
              ];
            # IP address should be set in the host-specific config like:
            # ipv4.addresses = [{ address = "10.1.1.2"; prefixLength = 32; }];
            # ipv6.addresses = [{ address = "fe80::8400:ff:fe7b:4d41"; prefixLength = 64; }];
          };
        }
        (lib.mkIf isGateway {
          eth0 = {
            ipv4.routes = [
              {
                address = gatewayAddress;
                prefixLength = 32;
              }
            ];
            # External IP should be set in the host-specific config like:
            # ipv4.addresses = [{ address = "157.180.42.128"; prefixLength = 32; }];
            # ipv6.addresses = [{ address = "fe80::9000:7ff:fe2f:f11c"; prefixLength = 64; }];
          };
        })
      ];
    };
  };
}
