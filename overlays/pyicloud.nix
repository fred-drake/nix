# Builds the PyiCloud CLI from the pinned uv.lock in apps/pyicloud, via
# uv2nix. Exposes `pkgs.pyicloud-cli`.
#
# This tracks the user's intended pip install:
#   pip install "pyicloud[cli]"
# but keeps source revisions and transitive dependencies deterministic. Bump
# PyiCloud with `uv lock --upgrade` in apps/pyicloud or `just update-pyicloud`.
{inputs}: final: _prev: let
  inherit (final) lib;

  python = final.python314;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../apps/pyicloud;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Per-package build-system fixups for wheels/sdists that ship incomplete
  # metadata. Git sources are built from source, and uv.lock does not carry
  # build-system metadata, so provide PyiCloud's declared build backend here.
  pyprojectOverrides = pyfinal: pyprev: {
    pyicloud = pyprev.pyicloud.overrideAttrs (old: {
      nativeBuildInputs =
        (old.nativeBuildInputs or [])
        ++ pyfinal.resolveBuildSystem {
          setuptools = [];
          setuptools-scm = [];
        };
    });
  };

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

  pyicloudEnv = pythonSet.mkVirtualEnv "pyicloud-env" workspace.deps.default;
in {
  pyicloud-cli = final.runCommand "pyicloud-cli" {nativeBuildInputs = [final.makeWrapper];} ''
    mkdir -p "$out/bin"
    makeWrapper ${pyicloudEnv}/bin/icloud "$out/bin/icloud"
  '';
}
