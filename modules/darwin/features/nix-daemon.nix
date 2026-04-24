{config, ...}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      cores = 0;
      sandbox = false;
      trusted-users = ["root" config.my.username];
    };
  };
}
