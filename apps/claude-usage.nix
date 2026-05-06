{pkgs}:
pkgs.writeShellApplication {
  name = "claude-usage";

  runtimeInputs = with pkgs; [curl jq];

  text = ''
    CREDENTIALS_FILE="$HOME/.claude/.credentials.json"
    creds=""

    if [[ -f "$CREDENTIALS_FILE" ]]; then
        creds=$(cat "$CREDENTIALS_FILE")
    elif [[ "$(uname)" == "Darwin" ]]; then
        # On macOS, Claude Code stores credentials in the login Keychain
        creds=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
    fi

    if [[ -z "$creds" ]]; then
        echo "Error: Could not load Claude Code credentials (file or Keychain)" >&2
        exit 1
    fi

    ACCESS_TOKEN=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.accessToken')

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
