{
  mcpServers = {
    brave-search = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-brave-search"];
    };
    nixos = {
      command = "uvx";
      args = ["mcp-nixos"];
    };
    sequential-thinking = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
    };
    time = {
      command = "uvx";
      args = ["mcp-server-time" "--local-timezone=America/New_York"];
    };
    wcgw = {
      command = "uv";
      args = ["tool" "run" "--from" "wcgw@latest" "--python" "3.12" "wcgw_mcp"];
    };
    playwright = {
      command = "npx";
      args = ["@playwright/mcp@latest"];
    };
    messages = {
      command = "uvx";
      args = ["mac-messages-mcp"];
    };
    probe = {
      command = "npx";
      args = ["-y" "@buger/probe-mcp"];
    };
  };
}
