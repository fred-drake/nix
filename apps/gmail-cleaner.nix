{
  lib,
  rustPlatform,
  makeWrapper,
  src,
}: let
  cargoToml = builtins.fromTOML (builtins.readFile "${src}/Cargo.toml");
in
  rustPlatform.buildRustPackage {
    pname = cargoToml.package.name;
    inherit (cargoToml.package) version;
    inherit src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = [makeWrapper];

    postFixup = ''
      wrapProgram $out/bin/gmail-cleaner --run '
        if [ -z "''${JEV_API_KEY:-}" ]; then
          for f in "$HOME/.config/sops-nix/secrets/gmail-cleaner-jev-api-key" "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/secrets/gmail-cleaner-jev-api-key"; do
            if [ -r "$f" ]; then
              export JEV_API_KEY="$(cat "$f")"
              break
            fi
          done
        fi
        if [ -z "''${GMAIL_CLIENT_ID:-}" ]; then
          for f in "$HOME/.config/sops-nix/secrets/google-workspace-client-id" "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/secrets/google-workspace-client-id"; do
            if [ -r "$f" ]; then
              export GMAIL_CLIENT_ID="$(cat "$f")"
              break
            fi
          done
        fi
        if [ -z "''${GMAIL_CLIENT_SECRET:-}" ]; then
          for f in "$HOME/.config/sops-nix/secrets/google-workspace-client-secret" "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/secrets/google-workspace-client-secret"; do
            if [ -r "$f" ]; then
              export GMAIL_CLIENT_SECRET="$(cat "$f")"
              break
            fi
          done
        fi
      '
    '';

    meta = {
      inherit (cargoToml.package) description;
      homepage = "https://gitea.internal.freddrake.com/fdrake/gmail-cleaner";
      mainProgram = "gmail-cleaner";
      platforms = lib.platforms.unix;
    };
  }
