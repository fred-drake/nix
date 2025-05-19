{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  # Import host configurations
  adguard1 = import ./hosts/adguard1.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  adguard2 = import ./hosts/adguard2.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  overseerr = import ./hosts/overseerr.nix {inherit self nixpkgs-stable secrets sops-nix;};
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
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  _adguard1 = adguard1._adguard1;
  _adguard2 = adguard2._adguard2;
  _overseerr = overseerr._overseerr;
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

  # Init configurations
  "adguard1-init" = adguard1."adguard1-init";
  "adguard2-init" = adguard2."adguard2-init";
  "overseerr-init" = overseerr."overseerr-init";
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

  # Full configurations
  "adguard1" = adguard1."adguard1";
  "adguard2" = adguard2."adguard2";
  "overseerr" = overseerr."overseerr";
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
}
