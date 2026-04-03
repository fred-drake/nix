{...}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 4;
          Minute = 30;
          Weekday = 2;
        }
      ];
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      cores = 0;
      sandbox = false;
      trusted-users = ["root" "fdrake"];
    };
  };
}
