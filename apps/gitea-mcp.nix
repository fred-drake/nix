{
  pkgs,
  lib,
  buildGoModule,
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
in
  buildGoModule rec {
    pname = "gitea-mcp";
    version = "unstable";

    src = repos-src.gitea-mcp-src;

    # Fix vendor inconsistency
    proxyVendor = true;

    vendorHash = "sha256-UEFE6B7fsIHED5KvRK0iD350NyQIP/mm2BlH06hjg5M=";

    # Build with version information like the Makefile does
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
    ];

    # The application expects to be built from the root directory
    subPackages = ["."];

    meta = with lib; {
      description = "Model Context Protocol (MCP) server for Gitea";
      homepage = "https://gitea.com/gitea/gitea-mcp";
      license = licenses.mit;
      maintainers = with maintainers; [];
      platforms = platforms.unix ++ platforms.darwin;
      mainProgram = "gitea-mcp";
    };
  }
