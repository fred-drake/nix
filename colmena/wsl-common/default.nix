# Common configuration module for WSL NixOS hosts
{
  pkgs,
  lib,
  ...
}: {
  wsl = {
    enable = true;
    defaultUser = "nixos";
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    ports = [22];
  };

  users.users.nixos = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
    # Fish as login shell — home-manager handles PATH setup, so
    # ignoreShellProgramCheck is safe (avoids broken fish 4.5.0 completion
    # generator from programs.fish.enable).
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };

  environment.shells = [pkgs.fish];

  sops.age.sshKeyPaths = ["/home/nixos/.ssh/id_ed25519"];

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = ["root" "@wheel"];
  };

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    rsync
  ];

  system.stateVersion = "25.11";
}
