{
  pkgs,
  buildNpmPackage,
  lib,
}: let
  repos-src = import ./fetcher/repos-src.nix {inherit pkgs;};
in
  buildNpmPackage {
    pname = "actual-mcp";
    version = "1.12.0";
    src = repos-src.actual-mcp-src;
    npmDepsHash = "sha256-LIUCc8uXwlAsqyB6Hvev2Ax1PR2iIRfi9bdxRgzlyYg=";

    meta = {
      description = "MCP server for Actual Budget";
      homepage = "https://github.com/s-stefanov/actual-mcp";
      license = lib.licenses.mit;
      mainProgram = "actual-mcp";
      platforms = lib.platforms.unix;
    };
  }
