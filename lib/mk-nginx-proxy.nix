# Helper to generate the standard nginx + ACME reverse-proxy fragment used
# by services in this flake. Returns a NixOS module fragment that wires:
#   - security.acme.certs."<host>.<domain>"
#   - services.nginx.virtualHosts."<host>.<domain>" (TLS + proxy_pass + websockets)
#
# The base domain is read from config.soft-secrets.networking.domain.
# Compose multiple fragments with lib.mkMerge.
{config}: {
  host,
  port,
  extraConfig ? "",
  extraLocations ? {},
  proxyWebsockets ? true,
}: let
  fqdn = "${host}.${config.soft-secrets.networking.domain}";
in {
  security.acme.certs.${fqdn} = {};
  services.nginx.virtualHosts.${fqdn} = {
    useACMEHost = fqdn;
    forceSSL = true;
    locations =
      {
        "/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          inherit proxyWebsockets extraConfig;
        };
      }
      // extraLocations;
  };
}
