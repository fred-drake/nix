# Re-export module: single entry point for shared Hetzner server configuration.
# Imports colmena/hetzner-common (hardware, networking, private-server settings).
{...}: {
  imports = [
    ../../colmena/hetzner-common
  ];
}
