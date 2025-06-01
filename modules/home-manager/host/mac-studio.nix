# Configuration specific to the Mac Studio
{config, ...}: {
  sops.secrets.wireguard-brainrush-stage = {
    sopsFile = config.secrets.host.mac-studio.wireguard-brainrush-stage;
    mode = "0400";
    key = "data";
  };
  home.file.".config/wireguard/brainrush-stage.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-brainrush-stage.path;

  home.file.".config/wireguard/brainrush-stage-public-key.txt".text = ''
    W4M1gUYVu4PPgqFfrE5bd5AVwyvxT1NokGApUrQy8DU=
  '';
}
