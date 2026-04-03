# Re-export module: single entry point for shared WSL NixOS configuration.
# Imports colmena/wsl-common (WSL settings, SSH, base packages).
{...}: {
  imports = [
    ../../colmena/wsl-common
  ];
}
