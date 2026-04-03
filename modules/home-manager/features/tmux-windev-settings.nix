{config, ...}: {
  home.file = {
    ".config/windev/config.json".text = builtins.toJSON config.soft-secrets.workstation.windev;
  };
}
