{pkgs, ...}: let
  mermaid-cli-wrapped = pkgs.callPackage ../../../apps/mermaid-cli-wrapped.nix {
    inherit (pkgs) stdenv;
  };
in {
  imports = [
    ../../../apps/tmux.nix
    ./tmux-windev-settings.nix
  ];

  programs = {
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batgrep
        batman
        batpipe
        prettybat
      ];
    };

    bottom.enable = true;

    yazi = {
      enable = true;
      shellWrapperName = "y";
    };
  };

  home.packages =
    (with pkgs; [
      btop
      chafa
      dua
      duf
      eza
      fastfetch
      fd
      highlight
      imgcat
      kondo
      ncdu
      presenterm
      ripgrep
      skim
      television
      tldr
      tmux
      tmux-mem-cpu-load
    ])
    ++ (
      if pkgs.stdenv.hostPlatform.isDarwin
      then [mermaid-cli-wrapped]
      else [pkgs.wl-clipboard]
    );
}
