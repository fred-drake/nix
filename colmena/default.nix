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
  gitea-runner-2 = import ./hosts/gitea-runner-2.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea-runner-3 = import ./hosts/gitea-runner-3.nix {inherit self nixpkgs-stable secrets sops-nix;};
  uptime-kuma = import ./hosts/uptime-kuma.nix {inherit self nixpkgs-stable secrets sops-nix;};
  sonarqube = import ./hosts/sonarqube.nix {inherit self nixpkgs-stable secrets sops-nix;};
  prometheus = import ./hosts/prometheus.nix {inherit self nixpkgs-stable secrets sops-nix;};
  grafana = import ./hosts/grafana.nix {inherit self nixpkgs-stable secrets sops-nix;};
  larussa = import ./hosts/larussa.nix {inherit self nixpkgs-stable secrets sops-nix;};
  external-metrics = import ./hosts/external-metrics.nix {inherit self nixpkgs-stable secrets sops-nix;};
  glance = import ./hosts/glance.nix {inherit self nixpkgs-stable secrets sops-nix;};
  arm64builder = import ./hosts/arm64builder.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  minio = import ./hosts/minio.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  scanner = import ./hosts/scanner.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  paperless = import ./hosts/paperless.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  woodpecker = import ./hosts/woodpecker.nix {inherit self nixpkgs-stable secrets sops-nix;};
  resume = import ./hosts/resume.nix {inherit self nixpkgs-stable secrets sops-nix;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  inherit (dns1) _dns1;
  inherit (dns2) _dns2;
  inherit (jellyseerr) _jellyseerr;
  inherit (prowlarr) _prowlarr;
  inherit (n8n) _n8n;
  inherit (gitea) _gitea;
  inherit (gitea-runner-1) _gitea-runner-1;
  inherit (gitea-runner-2) _gitea-runner-2;
  inherit (gitea-runner-3) _gitea-runner-3;
  inherit (uptime-kuma) _uptime-kuma;
  inherit (sonarqube) _sonarqube;
  inherit (prometheus) _prometheus;
  inherit (grafana) _grafana;
  inherit (larussa) _larussa;
  inherit (external-metrics) _external-metrics;
  inherit (glance) _glance;
  inherit (arm64builder) _arm64builder;
  inherit (minio) _minio;
  inherit (scanner) _scanner;
  inherit (paperless) _paperless;
  inherit (woodpecker) _woodpecker;
  inherit (resume) _resume;

  # Init configurations
  "dns1-init" = dns1."dns1-init";
  "dns2-init" = dns2."dns2-init";
  "jellyseerr-init" = jellyseerr."jellyseerr-init";
  "prowlarr-init" = prowlarr."prowlarr-init";
  "n8n-init" = n8n."n8n-init";
  "gitea-init" = gitea."gitea-init";
  "gitea-runner-1-init" = gitea-runner-1."gitea-runner-1-init";
  "gitea-runner-2-init" = gitea-runner-2."gitea-runner-2-init";
  "gitea-runner-3-init" = gitea-runner-3."gitea-runner-3-init";
  "uptime-kuma-init" = uptime-kuma."uptime-kuma-init";
  "sonarqube-init" = sonarqube."sonarqube-init";
  "prometheus-init" = prometheus."prometheus-init";
  "grafana-init" = grafana."grafana-init";
  "larussa-init" = larussa."larussa-init";
  "external-metrics-init" = external-metrics."external-metrics-init";
  "glance-init" = glance."glance-init";
  "arm64builder-init" = arm64builder."arm64builder-init";
  "minio-init" = minio."minio-init";
  "scanner-init" = scanner."scanner-init";
  "paperless-init" = paperless."paperless-init";
  "woodpecker-init" = woodpecker."woodpecker-init";
  "resume-init" = resume."resume-init";

  # Full configurations
  "dns1" = dns1."dns1";
  "dns2" = dns2."dns2";
  "jellyseerr" = jellyseerr."jellyseerr";
  "prowlarr" = prowlarr."prowlarr";
  "n8n" = n8n."n8n";
  "gitea" = gitea."gitea";
  "gitea-runner-1" = gitea-runner-1."gitea-runner-1";
  "gitea-runner-2" = gitea-runner-2."gitea-runner-2";
  "gitea-runner-3" = gitea-runner-3."gitea-runner-3";
  "uptime-kuma" = uptime-kuma."uptime-kuma";
  "sonarqube" = sonarqube."sonarqube";
  "prometheus" = prometheus."prometheus";
  "grafana" = grafana."grafana";
  "larussa" = larussa."larussa";
  "external-metrics" = external-metrics."external-metrics";
  "glance" = glance."glance";
  "arm64builder" = arm64builder."arm64builder";
  "minio" = minio."minio";
  "scanner" = scanner."scanner";
  "paperless" = paperless."paperless";
  "woodpecker" = woodpecker."woodpecker";
  "resume" = resume."resume";
}
