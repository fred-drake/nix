# Fish completions for the Claude Code CLI (`claude`).
#
# Hand-written from `claude --help` output (no built-in completion generator).
# Covers top-level options, subcommands, and the most useful nested options.

set -l claude_subcommands agents auth auto-mode doctor install mcp plugin plugins setup-token update upgrade

function __fish_claude_no_subcommand
    not __fish_seen_subcommand_from $argv
end

# ---------------------------------------------------------------------------
# Subcommands (only at the first positional)
# ---------------------------------------------------------------------------
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a agents       -d 'List configured agents'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a auth         -d 'Manage authentication'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a auto-mode    -d 'Inspect auto mode classifier configuration'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a doctor       -d 'Check auto-updater health'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a install      -d 'Install Claude Code native build'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a mcp          -d 'Configure and manage MCP servers'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a plugin       -d 'Manage Claude Code plugins'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a plugins      -d 'Manage Claude Code plugins (alias)'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a setup-token  -d 'Set up a long-lived authentication token'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a update       -d 'Check for updates and install if available'
complete -c claude -n "__fish_claude_no_subcommand $claude_subcommands" -a upgrade      -d 'Check for updates and install if available (alias)'

# ---------------------------------------------------------------------------
# Top-level options (apply before any subcommand)
# ---------------------------------------------------------------------------
complete -c claude -l add-dir                                    -r -F -d 'Additional directories to allow tool access to'
complete -c claude -l agent                                      -r    -d 'Agent for the current session'
complete -c claude -l agents                                     -r    -d 'JSON object defining custom agents'
complete -c claude -l allow-dangerously-skip-permissions               -d 'Enable bypassing all permission checks as an option'
complete -c claude -l allowedTools -l allowed-tools              -r    -d 'Tools to allow (e.g. "Bash(git *) Edit")'
complete -c claude -l append-system-prompt                       -r    -d 'Append to the default system prompt'
complete -c claude -l bare                                             -d 'Minimal mode: skip hooks, LSP, plugin sync, etc.'
complete -c claude -l betas                                      -r    -d 'Beta headers to include in API requests'
complete -c claude -l brief                                            -d 'Enable SendUserMessage tool for agent-to-user communication'
complete -c claude -l chrome                                           -d 'Enable Claude in Chrome integration'
complete -c claude -s c -l continue                                    -d 'Continue the most recent conversation in this dir'
complete -c claude -l dangerously-skip-permissions                     -d 'Bypass all permission checks'
complete -c claude -s d -l debug                                       -d 'Enable debug mode with optional category filtering'
complete -c claude -l debug-file                                 -r -F -d 'Write debug logs to a specific file path'
complete -c claude -l disable-slash-commands                           -d 'Disable all skills'
complete -c claude -l disallowedTools -l disallowed-tools        -r    -d 'Tools to deny'
complete -c claude -l effort                                     -r -f -a 'low medium high xhigh max' -d 'Effort level'
complete -c claude -l exclude-dynamic-system-prompt-sections           -d 'Move per-machine sections into the first user message'
complete -c claude -l fallback-model                             -r    -d 'Automatic fallback model when default is overloaded'
complete -c claude -l file                                       -r    -d 'File resources to download at startup'
complete -c claude -l fork-session                                     -d 'Create a new session ID when resuming'
complete -c claude -l from-pr                                          -d 'Resume a session linked to a PR'
complete -c claude -s h -l help                                        -d 'Display help for command'
complete -c claude -l ide                                              -d 'Auto-connect to IDE on startup'
complete -c claude -l include-hook-events                              -d 'Include all hook lifecycle events in output stream'
complete -c claude -l include-partial-messages                         -d 'Include partial message chunks as they arrive'
complete -c claude -l input-format                               -r -f -a 'text stream-json' -d 'Input format (only works with --print)'
complete -c claude -l json-schema                                -r    -d 'JSON Schema for structured output validation'
complete -c claude -l max-budget-usd                             -r    -d 'Maximum dollar amount to spend on API calls'
complete -c claude -l mcp-config                                 -r -F -d 'Load MCP servers from JSON files or strings'
complete -c claude -l mcp-debug                                        -d '[DEPRECATED] Enable MCP debug mode'
complete -c claude -l model                                      -r -f -a 'opus sonnet haiku claude-opus-4-7 claude-sonnet-4-6 claude-haiku-4-5-20251001' -d 'Model for the current session'
complete -c claude -s n -l name                                  -r    -d 'Display name for this session'
complete -c claude -l no-chrome                                        -d 'Disable Claude in Chrome integration'
complete -c claude -l no-session-persistence                           -d 'Disable session persistence'
complete -c claude -l output-format                              -r -f -a 'text json stream-json' -d 'Output format (only works with --print)'
complete -c claude -l permission-mode                            -r -f -a 'acceptEdits auto bypassPermissions default dontAsk plan' -d 'Permission mode for the session'
complete -c claude -l plugin-dir                                 -r -F -d 'Load plugins from a directory (repeatable)'
complete -c claude -s p -l print                                       -d 'Print response and exit (useful for pipes)'
complete -c claude -l remote-control-session-name-prefix         -r    -d 'Prefix for auto-generated Remote Control session names'
complete -c claude -l replay-user-messages                             -d 'Re-emit user messages from stdin back on stdout'
complete -c claude -s r -l resume                                      -d 'Resume a conversation by session ID'
complete -c claude -l session-id                                 -r    -d 'Use a specific session ID for the conversation'
complete -c claude -l setting-sources                            -r    -d 'Setting sources to load (user, project, local)'
complete -c claude -l settings                                   -r -F -d 'Path to settings JSON file or a JSON string'
complete -c claude -l strict-mcp-config                                -d 'Only use MCP servers from --mcp-config'
complete -c claude -l system-prompt                              -r    -d 'System prompt to use for the session'
complete -c claude -l tmux                                             -d 'Create a tmux session for the worktree'
complete -c claude -l tools                                      -r    -d 'List of available tools from the built-in set'
complete -c claude -l verbose                                          -d 'Override verbose mode setting from config'
complete -c claude -s v -l version                                     -d 'Output the version number'
complete -c claude -s w -l worktree                                    -d 'Create a new git worktree for this session'

# ---------------------------------------------------------------------------
# `claude mcp ...`
# ---------------------------------------------------------------------------
set -l mcp_subs add add-from-claude-desktop add-json get list remove reset-project-choices serve help
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a add                       -d 'Add an MCP server'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a add-from-claude-desktop   -d 'Import servers from Claude Desktop (Mac/WSL)'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a add-json                  -d 'Add an MCP server via JSON'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a get                       -d 'Get details about an MCP server'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a list                      -d 'List configured MCP servers'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a remove                    -d 'Remove an MCP server'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a reset-project-choices     -d 'Reset approved/rejected project-scoped servers'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a serve                     -d 'Start the Claude Code MCP server'
complete -c claude -n "__fish_seen_subcommand_from mcp; and not __fish_seen_subcommand_from $mcp_subs" -a help                      -d 'Display help for an mcp command'

complete -c claude -n '__fish_seen_subcommand_from mcp; and __fish_seen_subcommand_from add' -l transport -r -f -a 'stdio sse http' -d 'Transport type'
complete -c claude -n '__fish_seen_subcommand_from mcp; and __fish_seen_subcommand_from add' -s s -l scope -r -f -a 'local user project' -d 'Configuration scope'
complete -c claude -n '__fish_seen_subcommand_from mcp; and __fish_seen_subcommand_from add' -s e -l env -r -d 'Environment variables (KEY=VALUE)'
complete -c claude -n '__fish_seen_subcommand_from mcp; and __fish_seen_subcommand_from add' -s H -l header -r -d 'HTTP headers (for http/sse)'

# ---------------------------------------------------------------------------
# `claude plugin ...` (alias: plugins)
# ---------------------------------------------------------------------------
set -l plugin_subs disable enable install i list marketplace uninstall remove update validate help
for pcmd in plugin plugins
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a disable     -d 'Disable an enabled plugin'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a enable      -d 'Enable a disabled plugin'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a install     -d 'Install a plugin from available marketplaces'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a list        -d 'List installed plugins'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a marketplace -d 'Manage Claude Code marketplaces'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a uninstall   -d 'Uninstall an installed plugin'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a remove      -d 'Uninstall an installed plugin (alias)'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a update      -d 'Update a plugin to the latest version'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a validate    -d 'Validate a plugin or marketplace manifest'
    complete -c claude -n "__fish_seen_subcommand_from $pcmd; and not __fish_seen_subcommand_from $plugin_subs" -a help        -d 'Display help for a plugin command'
end

# ---------------------------------------------------------------------------
# `claude auth ...`
# ---------------------------------------------------------------------------
set -l auth_subs login logout status help
complete -c claude -n "__fish_seen_subcommand_from auth; and not __fish_seen_subcommand_from $auth_subs" -a login  -d 'Sign in to your Anthropic account'
complete -c claude -n "__fish_seen_subcommand_from auth; and not __fish_seen_subcommand_from $auth_subs" -a logout -d 'Log out from your Anthropic account'
complete -c claude -n "__fish_seen_subcommand_from auth; and not __fish_seen_subcommand_from $auth_subs" -a status -d 'Show authentication status'
complete -c claude -n "__fish_seen_subcommand_from auth; and not __fish_seen_subcommand_from $auth_subs" -a help   -d 'Display help for an auth command'

# ---------------------------------------------------------------------------
# `claude install ...`
# ---------------------------------------------------------------------------
complete -c claude -n '__fish_seen_subcommand_from install' -l force -d 'Force installation even if already installed'
complete -c claude -n '__fish_seen_subcommand_from install' -a 'stable latest' -d 'Version channel'

# ---------------------------------------------------------------------------
# `claude agents ...`
# ---------------------------------------------------------------------------
complete -c claude -n '__fish_seen_subcommand_from agents' -l setting-sources -r -d 'Setting sources to load'
