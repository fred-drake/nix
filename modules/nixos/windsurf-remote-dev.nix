{pkgs, ...}: {
  # Needed for Windsurf SSH
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    nodejs
  ];
}
