{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";

  # Import host configurations
  adguard1 = import ./hosts/adguard1.nix {inherit self nixpkgs-stable nixpkgs-unstable nixos-hardware secrets sops-nix;};
  adguard2 = import ./hosts/adguard2.nix {inherit self nixpkgs-stable nixpkgs-unstable nixos-hardware secrets sops-nix;};
  overseerr = import ./hosts/overseerr.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  sonarr = import ./hosts/sonarr.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  radarr = import ./hosts/radarr.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  prowlarr = import ./hosts/prowlarr.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  sabnzbd = import ./hosts/sabnzbd.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  n8n = import ./hosts/n8n.nix {inherit self nixpkgs-stable nixpkgs-unstable secrets sops-nix;};
  colmena = import ./colmena {
    inherit self nixpkgs-stable nixpkgs-unstable nixos-hardware secrets sops-nix;
  };
in {
  meta = {
    nixpkgs = import nixpkgs-stable {system = "aarch64-linux";};
  };

  # Merge all host configurations
  # Base configurations
  _adguard1 = adguard1._adguard1;
  _adguard2 = adguard2._adguard2;
  _overseerr = overseerr._overseerr;
  _sonarr = sonarr._sonarr;
  _radarr = radarr._radarr;
  _prowlarr = prowlarr._prowlarr;
  _sabnzbd = sabnzbd._sabnzbd;
  _n8n = n8n._n8n;

  # Init configurations
  "adguard1-init" = adguard1."adguard1-init";
  "adguard2-init" = adguard2."adguard2-init";
  "overseerr-init" = overseerr."overseerr-init";
  "sonarr-init" = sonarr."sonarr-init";
  "radarr-init" = radarr."radarr-init";
  "prowlarr-init" = prowlarr."prowlarr-init";
  "sabnzbd-init" = sabnzbd."sabnzbd-init";
  "n8n-init" = n8n."n8n-init";

  # Full configurations
  "adguard1" = adguard1."adguard1";
  "adguard2" = adguard2."adguard2";
  "overseerr" = overseerr."overseerr";
  "sonarr" = sonarr."sonarr";
  "radarr" = radarr."radarr";
  "prowlarr" = prowlarr."prowlarr";
  "sabnzbd" = sabnzbd."sabnzbd";
  "n8n" = n8n."n8n";
}
