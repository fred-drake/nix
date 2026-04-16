{pkgs, ...}: {
  home.packages = with pkgs; [
    age
    curl
    gnupg
    hclfmt
    inetutils
    lsof
    minio-client
    openssl
    restic
    rsync
    smartmontools
    sops
    stc-cli
    syncthing
    unzip
    wget
    wireguard-tools
    woodpecker-cli
  ];
}
