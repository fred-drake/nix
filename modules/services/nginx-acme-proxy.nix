# Shared ACME + Cloudflare DNS validation + nginx reverse proxy settings.
#
# Hosts importing this module must also provide the `cloudflare-api-key`
# sops secret (either via modules/secrets/cloudflare.nix or their own
# host-specific secrets file).
{config, ...}: {
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults = {
      inherit (config.soft-secrets.acme) email;
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
}
