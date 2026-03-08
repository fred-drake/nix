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

  launchd.agents.archive-email = {
    enable = true;
    config = {
      Label = "com.freddrake.archive-email";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "cd $HOME/Source/gitea.internal.freddrake.com/fdrake/PKM-Personal && claude --model sonnet -p /archive-obvious"
      ];
      StartInterval = 14400; # every 4 hours (in seconds)
      StandardOutPath = "/tmp/archive-email.log";
      StandardErrorPath = "/tmp/archive-email.err";
    };
  };
}
