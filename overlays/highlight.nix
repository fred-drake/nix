# highlight 4.20 in nixpkgs-unstable still applies shellscript-crash-fix.patch,
# but that fix is already present in the 4.20 release source, so patchPhase
# aborts with "Reversed (or previously applied) patch detected" and the build
# fails. It is highlight's only patch, so filter it out. Remove this overlay
# once nixpkgs stops shipping the now-redundant patch.
#
# Kept standalone (like overlays/glance.nix) so it can be applied both through
# mkPkgs and directly onto the bare unstable nodeNixpkgs for anton/gnomeregan
# in colmena/default.nix, which does not go through mkPkgs.
_final: prev: {
  # WORKAROUND(highlight): obsolete shellscript-crash-fix.patch double-applies
  #   against the 4.20 source; remove when nixpkgs stops shipping the patch.
  highlight = prev.highlight.overrideAttrs (old: {
    patches =
      builtins.filter
      (p: !(prev.lib.hasInfix "shellscript-crash-fix" (baseNameOf (toString p))))
      (old.patches or []);
  });
}
