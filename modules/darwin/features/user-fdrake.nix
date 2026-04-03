{pkgs, ...}: {
  users = {
    knownUsers = ["fdrake"];
    users.fdrake = {
      uid = 501;
      home = "/Users/fdrake";
      shell = pkgs.fish;
    };
  };

  system.primaryUser = "fdrake";

  environment.shells = with pkgs; [
    bash
    zsh
    fish
    nushell
  ];
}
