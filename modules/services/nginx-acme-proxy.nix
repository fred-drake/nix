# Shared ACME + Cloudflare DNS validation + nginx reverse proxy settings.
# Provides the cloudflare-api-key sops secret used by ACME DNS challenges.
{config, ...}: {
  sops = {
    defaultSopsFile = config.secrets.sopsYaml;
    secrets.cloudflare-api-key = {
      sopsFile = config.secrets.cloudflare.letsencrypt-token;
      mode = "0400";
      key = "data";
    };
  };

  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults = {
      inherit (config.soft-secrets.acme) email;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      group = "nginx";
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    # Increase hash table size for proxy headers — needed when
    # recommendedProxySettings adds headers alongside per-location ones.
    appendHttpConfig = ''
      proxy_headers_hash_max_size 1024;
      proxy_headers_hash_bucket_size 128;
    '';
  };
}
