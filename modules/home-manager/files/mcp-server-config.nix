{
  "mcpServers" = {
    "brave-search" = {
      "command" = "npx";
      "args" = ["-y" "@modelcontextprotocol/server-brave-search"];
    };
    "nixos" = {
      "command" = "uvx";
      "args" = ["mcp-nixos"];
    };
    "sequential-thinking" = {
      "command" = "npx";
      "args" = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
    };
    "time" = {
      "command" = "uvx";
      "args" = ["mcp-server-time" "--local-timezone=America/New_York"];
    };
  };
}
