{pkgs}:
pkgs.writeShellApplication {
  name = "claude-usage";

  runtimeInputs = with pkgs; [curl jq];

  text = ''
    CREDENTIALS_FILE="$HOME/.claude/.credentials.json"

    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        echo "Error: Credentials file not found at $CREDENTIALS_FILE" >&2
        exit 1
    fi

    ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS_FILE")

    if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
        echo "Error: Could not extract access token from credentials" >&2
        exit 1
    fi

    curl -s "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json"
  '';

  meta = {
    description = "Get Claude Code usage data in JSON format";
    mainProgram = "claude-usage";
  };
}
