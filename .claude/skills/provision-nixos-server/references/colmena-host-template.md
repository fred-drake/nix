# Colmena Host Configuration Template

## File: colmena/hosts/<hostname>.nix

```nix
{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  _<hostname> = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };

    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/<hostname>/configuration.nix
      ../../modules/secrets/cloudflare.nix  # If using nginx with SSL
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.<hostname>.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "<hostname>-init" = {
    imports = [
      self.colmena._<hostname>
    ];
  };

  # Full configuration
  "<hostname>" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._<hostname>
      ../../modules/secrets/<hostname>.nix
      ../../apps/<appname>.nix
      (nodeExporter.mkNodeExporter "<hostname>")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
```

## Updates to colmena/default.nix

Add three sections:

1. Import statement (near top with other imports):
```nix
<hostname> = import ./hosts/<hostname>.nix {inherit self nixpkgs-stable secrets sops-nix;};
```

2. Inherit statement (in the inherit section):
```nix
inherit (<hostname>) _<hostname>;
```

3. Init configuration (in "# Init configurations" section):
```nix
"<hostname>-init" = <hostname>."<hostname>-init";
```

4. Full configuration (in "# Full configurations" section):
```nix
"<hostname>" = <hostname>."<hostname>";
```

## Initial Deploy Pattern

For first-time deployment before static IP is configured:

```nix
deployment = {
  buildOnTarget = false;
  targetHost = "<DHCP_IP_ADDRESS>";  # Temporary DHCP IP
  targetUser = "root";  # Root access before default user exists
};
```

After initial deploy changes the IP, update to use soft-secrets and default user.
