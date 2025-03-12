# Configuration specific to the MacBook Pro device.
{config, ...}: {
  sops.secrets.wireguard-office-admin = {
    sopsFile = config.secrets.host.macbookpro.wireguard-office-admin;
    mode = "0400";
    key = "data";
  };
  home.file.".config/wireguard/office-admin.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-office-admin.path;

  sops.secrets.wireguard-office-full = {
    sopsFile = config.secrets.host.macbookpro.wireguard-office-full;
    mode = "0400";
    key = "data";
  };
  home.file.".config/wireguard/office-full.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-office-full.path;

  sops.secrets.wireguard-office-public-dns = {
    sopsFile = config.secrets.host.macbookpro.wireguard-office-public-dns;
    mode = "0400";
    key = "data";
  };
  home.file.".config/wireguard/office-public-dns.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-office-public-dns.path;

  home.file.".config/wireguard/public-key.txt".text = ''
    GK82AkQED91xMMqZ7RXpAu8LwFC2BiTsAsnwzR47B2w=
  '';
}
