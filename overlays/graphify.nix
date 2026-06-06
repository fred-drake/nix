# Builds the Graphify CLI (PyPI: graphifyy) as a Nix-managed virtualenv from
# the pinned uv.lock in apps/graphify, via uv2nix. Exposes `pkgs.graphify`.
#
# Why uv2nix instead of buildPythonApplication: Graphify depends on graspologic,
# whose transitive deps (future, sphinx) break under adjacent CPython versions
# in nixpkgs (3.13 and 3.11 both fail; only 3.12 evaluates). Consuming upstream
# wheels through the lock avoids the nixpkgs Python set entirely, so a nixpkgs
# bump can't silently break the build. Bump Graphify with `uv lock --upgrade`
# in apps/graphify.
{inputs}: final: _prev: let
  inherit (final) lib;

  python = final.python312;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../apps/graphify;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Per-package build-system fixups for wheels/sdists that ship incomplete
  # metadata. Kept empty until a build actually demands an entry — add the
  # narrowest override here rather than relaxing globally.
  pyprojectOverrides = _pyfinal: _pyprev: {};

  pythonSet =
    (final.callPackage inputs.pyproject-nix.build.packages {
      inherit python;
    })
    .overrideScope (
      lib.composeManyExtensions [
        inputs.pyproject-build-systems.overlays.default
        overlay
        pyprojectOverrides
      ]
    );
in {
  graphify = pythonSet.mkVirtualEnv "graphify-env" workspace.deps.default;
}
