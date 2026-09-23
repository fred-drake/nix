# WORKAROUND(sops-install-secrets): sops-nix pinned revision fbf75929 relies on
# buildGo125Module which was removed in nixpkgs-unstable; alias to buildGoModule
# until sops-nix is updated across nixpkgs-stable and nixpkgs-unstable.
_final: prev: {
  buildGo125Module = prev.buildGoModule;
}
