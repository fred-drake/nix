{
  pkgs,
  lib,
  buildGoModule,
}: let
  repos-src = import ../../../../apps/fetcher/repos-src.nix {inherit pkgs;};
in
  buildGoModule rec {
    pname = "kuma-waybar";
    version = "unstable";

    src = repos-src.kuma-waybar-src;

    vendorHash = null;

    # Build with version information
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
    ];

    # The application expects to be built from the root directory
    subPackages = ["."];

    meta = with lib; {
      description = "Uptime Kuma integration for Waybar";
      homepage = "https://github.com/WebTender/kuma-waybar";
      license = licenses.mit;
      maintainers = with maintainers; [];
      platforms = platforms.unix ++ platforms.darwin;
      mainProgram = "kuma-waybar";
    };
  }
