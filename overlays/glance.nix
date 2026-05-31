# Build glance from its main branch (input glance-src) instead of the tagged
# nixpkgs release. Reuses the upstream derivation's ldflags, meta, and install
# check — only the source, version, and vendorHash change. `nix flake update
# glance-src` pulls the latest main commit; bump vendorHash here if go.mod
# changes (the build error prints the new hash).
#
# Kept as a standalone overlay so it can be applied both through mkPkgs
# (overlays/default.nix) and directly onto gnomeregan's bare nodeNixpkgs in
# colmena/default.nix, which does not go through mkPkgs.
{inputs}: _final: prev: {
  glance = prev.glance.overrideAttrs (_: {
    version = "main-${inputs.glance-src.shortRev or "dirty"}";
    src = inputs.glance-src;
    vendorHash = "sha256-a92V/duqvrWEb8QSJLA5rHYYZCcJ4fBC962SEr4FJDA=";
  });
}
