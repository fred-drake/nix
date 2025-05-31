{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  # Import host configurations
  dns1 = import ./hosts/dns1.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  dns2 = import ./hosts/dns2.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  jellyseerr = import ./hosts/jellyseerr.nix {inherit self nixpkgs-stable secrets sops-nix;};
  prowlarr = import ./hosts/prowlarr.nix {inherit self nixpkgs-stable secrets sops-nix;};
  n8n = import ./hosts/n8n.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea = import ./hosts/gitea.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea-runner-1 = import ./hosts/gitea-runner-1.nix {inherit self nixpkgs-stable secrets sops-nix;};
  uptime-kuma = import ./hosts/uptime-kuma.nix {inherit self nixpkgs-stable secrets sops-nix;};
  prometheus = import ./hosts/prometheus.nix {inherit self nixpkgs-stable secrets sops-nix;};
  grafana = import ./hosts/grafana.nix {inherit self nixpkgs-stable secrets sops-nix;};
  larussa = import ./hosts/larussa.nix {inherit self nixpkgs-stable secrets sops-nix;};
  external-metrics = import ./hosts/external-metrics.nix {inherit self nixpkgs-stable secrets sops-nix;};
  glance = import ./hosts/glance.nix {inherit self nixpkgs-stable secrets sops-nix;};
  arm64builder = import ./hosts/arm64builder.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  minio = import ./hosts/minio.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  _dns1 = dns1._dns1;
  _dns2 = dns2._dns2;
  _jellyseerr = jellyseerr._jellyseerr;
  _prowlarr = prowlarr._prowlarr;
  _n8n = n8n._n8n;
  _gitea = gitea._gitea;
  _gitea-runner-1 = gitea-runner-1._gitea-runner-1;
  _uptime-kuma = uptime-kuma._uptime-kuma;
  _prometheus = prometheus._prometheus;
  _grafana = grafana._grafana;
  _larussa = larussa._larussa;
  _external-metrics = external-metrics._external-metrics;
  _glance = glance._glance;
  _arm64builder = arm64builder._arm64builder;
  _minio = minio._minio;

  # Init configurations
  "dns1-init" = dns1."dns1-init";
  "dns2-init" = dns2."dns2-init";
  "jellyseerr-init" = jellyseerr."jellyseerr-init";
  "prowlarr-init" = prowlarr."prowlarr-init";
  "n8n-init" = n8n."n8n-init";
  "gitea-init" = gitea."gitea-init";
  "gitea-runner-1-init" = gitea-runner-1."gitea-runner-1-init";
  "uptime-kuma-init" = uptime-kuma."uptime-kuma-init";
  "prometheus-init" = prometheus."prometheus-init";
  "grafana-init" = grafana."grafana-init";
  "larussa-init" = larussa."larussa-init";
  "external-metrics-init" = external-metrics."external-metrics-init";
  "glance-init" = glance."glance-init";
  "arm64builder-init" = arm64builder."arm64builder-init";
  "minio-init" = minio."minio-init";

  # Full configurations
  "dns1" = dns1."dns1";
  "dns2" = dns2."dns2";
  "jellyseerr" = jellyseerr."jellyseerr";
  "prowlarr" = prowlarr."prowlarr";
  "n8n" = n8n."n8n";
  "gitea" = gitea."gitea";
  "gitea-runner-1" = gitea-runner-1."gitea-runner-1";
  "uptime-kuma" = uptime-kuma."uptime-kuma";
  "prometheus" = prometheus."prometheus";
  "grafana" = grafana."grafana";
  "larussa" = larussa."larussa";
  "external-metrics" = external-metrics."external-metrics";
  "glance" = glance."glance";
  "arm64builder" = arm64builder."arm64builder";
  "minio" = minio."minio";
}
