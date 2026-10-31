# Configuration specific to the MacBook Pro device.
#
# Tailscale on this host is the GUI menubar app, installed via the
# `tailscale-app` Homebrew cask in modules/darwin/features/workstation-apps.nix.
# The app bundles its own daemon and CLI, so the nixpkgs `tailscale` package is
# intentionally NOT installed here — its CLI cannot talk to the app's sandboxed
# daemon and would only add a confusing, non-functional binary to $PATH.
{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = [
      pkgs.gmail-cleaner
    ];

    file.".config/gmail-cleaner/prompt.txt" = {
      text = config.soft-secrets.app.gmail-cleaner.prompt;
      force = true;
    };
  };
}
