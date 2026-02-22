{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  nixarr,
  ...
}: let
  # Import host configurations
  jellyseerr = import ./hosts/jellyseerr.nix {inherit self nixpkgs-stable secrets sops-nix;};
  prowlarr = import ./hosts/prowlarr.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea-runner-1 = import ./hosts/gitea-runner-1.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea-runner-2 = import ./hosts/gitea-runner-2.nix {inherit self nixpkgs-stable secrets sops-nix;};
  gitea-runner-3 = import ./hosts/gitea-runner-3.nix {inherit self nixpkgs-stable secrets sops-nix;};
  uptime-kuma = import ./hosts/uptime-kuma.nix {inherit self nixpkgs-stable secrets sops-nix;};
  sonarqube = import ./hosts/sonarqube.nix {inherit self nixpkgs-stable secrets sops-nix;};
  prometheus = import ./hosts/prometheus.nix {inherit self nixpkgs-stable secrets sops-nix;};
  grafana = import ./hosts/grafana.nix {inherit self nixpkgs-stable secrets sops-nix;};
  external-metrics = import ./hosts/external-metrics.nix {inherit self nixpkgs-stable secrets sops-nix;};
  scanner = import ./hosts/scanner.nix {inherit self nixpkgs-stable nixos-hardware secrets sops-nix;};
  resume = import ./hosts/resume.nix {inherit self nixpkgs-stable secrets sops-nix;};
  headscale = import ./hosts/headscale.nix {inherit self nixpkgs-stable secrets sops-nix;};
  ironforge = import ./hosts/ironforge.nix {inherit self nixpkgs-stable secrets sops-nix nixarr;};
  orgrimmar = import ./hosts/orgrimmar.nix {inherit self nixpkgs-stable secrets sops-nix;};
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  inherit (jellyseerr) _jellyseerr;
  inherit (prowlarr) _prowlarr;
  inherit (gitea-runner-1) _gitea-runner-1;
  inherit (gitea-runner-2) _gitea-runner-2;
  inherit (gitea-runner-3) _gitea-runner-3;
  inherit (uptime-kuma) _uptime-kuma;
  inherit (sonarqube) _sonarqube;
  inherit (prometheus) _prometheus;
  inherit (grafana) _grafana;
  inherit (external-metrics) _external-metrics;
  inherit (scanner) _scanner;
  inherit (resume) _resume;
  inherit (headscale) _headscale;
  inherit (ironforge) _ironforge;
  inherit (orgrimmar) _orgrimmar;

  # Init configurations
  "jellyseerr-init" = jellyseerr."jellyseerr-init";
  "prowlarr-init" = prowlarr."prowlarr-init";
  "gitea-runner-1-init" = gitea-runner-1."gitea-runner-1-init";
  "gitea-runner-2-init" = gitea-runner-2."gitea-runner-2-init";
  "gitea-runner-3-init" = gitea-runner-3."gitea-runner-3-init";
  "uptime-kuma-init" = uptime-kuma."uptime-kuma-init";
  "sonarqube-init" = sonarqube."sonarqube-init";
  "prometheus-init" = prometheus."prometheus-init";
  "grafana-init" = grafana."grafana-init";
  "external-metrics-init" = external-metrics."external-metrics-init";
  "scanner-init" = scanner."scanner-init";
  "resume-init" = resume."resume-init";
  "headscale-init" = headscale."headscale-init";
  "ironforge-init" = ironforge."ironforge-init";
  "orgrimmar-init" = orgrimmar."orgrimmar-init";

  # Full configurations
  "jellyseerr" = jellyseerr."jellyseerr";
  "prowlarr" = prowlarr."prowlarr";
  "gitea-runner-1" = gitea-runner-1."gitea-runner-1";
  "gitea-runner-2" = gitea-runner-2."gitea-runner-2";
  "gitea-runner-3" = gitea-runner-3."gitea-runner-3";
  "uptime-kuma" = uptime-kuma."uptime-kuma";
  "sonarqube" = sonarqube."sonarqube";
  "prometheus" = prometheus."prometheus";
  "grafana" = grafana."grafana";
  "external-metrics" = external-metrics."external-metrics";
  "scanner" = scanner."scanner";
  "resume" = resume."resume";
  "headscale" = headscale."headscale";
  "ironforge" = ironforge."ironforge";
  "orgrimmar" = orgrimmar."orgrimmar";
}
