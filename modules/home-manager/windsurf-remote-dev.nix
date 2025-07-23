{
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
in {
  # Tie Windsurf extensions to the server used for SSH connections
  home.activation = {
    windsurf-extensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
      mkdir -p ${home}/.windsurf-server
      rm -rf ${home}/.windsurf-server/extensions
      ln -s $EXT_DIR ${home}/.windsurf-server
    '';
  };
}
