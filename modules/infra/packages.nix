_: {
  perSystem = {pkgs, ...}: {
    packages = {
      buzz-acp = pkgs.callPackage ../../apps/buzz-acp.nix {};
      buzz-backend-gnomeregan = pkgs.callPackage ../../apps/buzz-backend-gnomeregan.nix {};
      codex = pkgs.callPackage ../../apps/codex.nix {};
      codex-acp = pkgs.callPackage ../../apps/codex-acp.nix {
        npm-packages = import ../../apps/fetcher/npm-packages.nix;
      };
    };

    checks = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      buzz-agent-ssh = pkgs.callPackage ../../tests/buzz-agent-ssh.nix {};
      buzz-agent-systemd = pkgs.callPackage ../../tests/buzz-agent-systemd.nix {};
    };
  };
}
