# cmux keyboard shortcuts — tmux-style bindings mirroring apps/tmux.nix.
#
# Fully declarative: home-manager owns ~/.config/cmux/cmux.json, so the cmux
# in-app Settings UI can no longer persist shortcut edits while this is active.
# Only shortcut bindings are set here; every other cmux setting still falls back
# to the value saved in the app.
#
# Leader key is C-a (matches the tmux prefix in apps/tmux.nix). Change the single
# `leader` line below to re-leader every chord at once.
{
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".config/cmux/cmux.json".text = let
    leader = "ctrl+a";
    chord = key: [leader key];
  in
    builtins.toJSON {
      "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
      schemaVersion = 1;
      shortcuts.bindings = {
        # Pane focus — prefix-LESS Ctrl+h/j/k/l, mirroring the root-table
        # vim-tmux-navigator bindings in apps/tmux.nix. Note: cmux has no is_vim
        # fallback, so these intercept Ctrl+h/j/k/l from nvim splits running
        # inside a cmux pane.
        focusLeft = "ctrl+h";
        focusDown = "ctrl+j";
        focusUp = "ctrl+k";
        focusRight = "ctrl+l";

        # Splits — your `prefix |` (split -h) and `prefix -` (split -v).
        # `\` instead of `|`: same physical key, unshifted, so the chord's
        # second stroke is clean (cmux mishandles the shifted `|`).
        splitRight = chord "\\";
        splitDown = chord "-";

        # Surfaces (tabs) stand in for tmux "windows".
        newSurface = chord "c"; # prefix c   -> new-window
        closeTab = chord "shift+k"; # prefix K   -> kill-window
        nextSurface = chord "n"; # prefix n   -> next-window
        prevSurface = chord "p"; # prefix p   -> previous-window
        selectSurfaceByNumber = chord "1"; # prefix 1-9 -> select-window
        renameTab = chord ","; # prefix ,   -> rename-window

        # Remaining prefix bindings.
        toggleTerminalCopyMode = chord "v"; # prefix v -> copy-mode
        reloadConfiguration = chord "r"; # prefix r -> source-file (reload)
        toggleSplitZoom = chord "z"; # prefix z -> zoom (the one you asked about)
        equalizeSplits = chord "="; # bonus: balance split sizes
      };
    };
}
