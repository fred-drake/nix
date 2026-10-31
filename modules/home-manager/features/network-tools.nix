{pkgs, ...}: {
  home.packages = with pkgs; [
    age
    curl
    gnupg
    hclfmt
    inetutils
    lsof
    openssl
    rclone
    restic
    rsync
    smartmontools
    sops
    stc-cli
    syncthing
    unzip
    wget
    woodpecker-cli
  ];
}
