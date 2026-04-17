# Configuration specific to the Mac Studio
{
  config,
  lib,
  ...
}: {
  sops.secrets.wireguard-brainrush-stage = {
    sopsFile = config.secrets.host.mac-studio.wireguard-brainrush-stage;
    mode = "0400";
    key = "data";
  };

  home.file = {
    ".config/wireguard/brainrush-stage.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-brainrush-stage.path;

    ".config/wireguard/brainrush-stage-public-key.txt".text = ''
      W4M1gUYVu4PPgqFfrE5bd5AVwyvxT1NokGApUrQy8DU=
    '';

    # Override ghostty config for mac-studio with larger font size
    ".config/ghostty/config" = lib.mkForce {
      text = ''
        app-notifications = no-clipboard-copy
        # Mac Studio specific: increase font size
        font-size = 16
      '';
    };
  };

  launchd.agents.process-daily = {
    enable = true;
    config = {
      Label = "com.freddrake.process-daily";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "export PATH=\"$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/fdrake/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH\" && YESTERDAY=$(date -d 'yesterday' '+%Y-%m-%d') && $HOME/Source/gitea.${config.soft-secrets.networking.domain}/fdrake/PKM-Personal/.claude/hooks/process-daily-cron.sh \"$YESTERDAY\""
      ];
      StartCalendarInterval = [
        {
          Hour = 0;
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/process-daily.log";
      StandardErrorPath = "/tmp/process-daily.err";
    };
  };

  launchd.agents.archive-email = {
    enable = true;
    config = {
      Label = "com.freddrake.archive-email";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "export PATH=\"$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/fdrake/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH\" && cd $HOME/Source/gitea.${config.soft-secrets.networking.domain}/fdrake/PKM-Personal && timeout 1200 claude --model sonnet --verbose --output-format stream-json -p /archive-obvious"
      ];
      StartCalendarInterval = [
        {
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/archive-email.log";
      StandardErrorPath = "/tmp/archive-email.err";
    };
  };
}
