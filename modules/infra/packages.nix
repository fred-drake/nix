_: {
  perSystem = {pkgs, ...}: {
    packages = {
      codex = pkgs.callPackage ../../apps/codex.nix {};
      codex-acp = pkgs.callPackage ../../apps/codex-acp.nix {
        npm-packages = import ../../apps/fetcher/npm-packages.nix;
      };
    };
  };
}
