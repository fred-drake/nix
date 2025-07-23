{
  fileSystems = {
    "/export/videos" = {
      device = "/mnt/array/storage1/videos";
      options = ["bind"];
    };

    "/export/sabnzbd_downloads" = {
      device = "/mnt/array/storage1/sabnzbd_downloads";
      options = ["bind"];
    };

    "/export/sabnzbd_downloads_incomplete" = {
      device = "/mnt/array/storage1/sabnzbd_downloads_incomplete";
      options = ["bind"];
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /export                              192.168.50.0/24(rw,sync,crossmnt,fsid=0,no_subtree_check,anonuid=99,anongid=100,all_squash)
      /export/videos                       192.168.50.0/24(fsid=1,sec=sys,rw,sync,no_subtree_check,anonuid=99,anongid=100,all_squash)
      /export/sabnzbd_downloads            192.168.50.0/24(fsid=2,sec=sys,rw,sync,no_subtree_check,anonuid=99,anongid=100,all_squash)
      /export/sabnzbd_downloads_incomplete 192.168.50.0/24(fsid=3,sec=sys,rw,sync,no_subtree_check,anonuid=99,anongid=100,all_squash)
    '';
  };
}
