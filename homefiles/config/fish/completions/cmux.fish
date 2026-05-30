# Fish completions for the cmux CLI (`cmux`).
#
# Hand-written from `cmux --help` (and the per-subcommand `--help` pages) output.
# cmux has no built-in completion generator, so this is maintained by hand the
# same way as claude.fish. Regenerate by re-reading `cmux <cmd> --help`.
#
# Covers top-level commands, global options, common context flags
# (--workspace/--surface/--window/--pane/--panel/--focus), enum-valued flags,
# and the nested subcommand trees (docs, settings, config, themes, hooks, vm,
# auth, feed, browser, surface, right-sidebar, set-app-focus).

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Dynamic theme names for `cmux themes set`.
function __cmux_themes
    cmux themes list 2>/dev/null \
        | string match -rv '^(Current|Config):' \
        | string trim \
        | string match -rv '^$'
end

# True when the cursor is inside a `browser` invocation.
function __cmux_in_browser
    __fish_seen_subcommand_from browser
end

# ---------------------------------------------------------------------------
# Top-level commands (offered at the first positional; file/dir completion
# stays enabled because `cmux <path>` opens a directory).
# ---------------------------------------------------------------------------
complete -c cmux -n __fish_use_subcommand -a welcome -d 'Show the welcome screen'
complete -c cmux -n __fish_use_subcommand -a docs -d 'Print canonical docs URL for a topic'
complete -c cmux -n __fish_use_subcommand -a settings -d 'Open Settings or print cmux.json paths'
complete -c cmux -n __fish_use_subcommand -a config -d 'Inspect cmux.json or reload the app'
complete -c cmux -n __fish_use_subcommand -a shortcuts -d 'List keyboard shortcuts'
complete -c cmux -n __fish_use_subcommand -a disable-browser -d 'Disable the browser feature'
complete -c cmux -n __fish_use_subcommand -a enable-browser -d 'Enable the browser feature'
complete -c cmux -n __fish_use_subcommand -a browser-status -d 'Show browser feature status'
complete -c cmux -n __fish_use_subcommand -a restore-session -d 'Restore the previous session'
complete -c cmux -n __fish_use_subcommand -a open -d 'Open paths/URLs in a workspace'
complete -c cmux -n __fish_use_subcommand -a feedback -d 'Send feedback to the cmux team'
complete -c cmux -n __fish_use_subcommand -a feed -d 'Open the Feed TUI or manage history'
complete -c cmux -n __fish_use_subcommand -a themes -d 'List/set/clear app themes'
complete -c cmux -n __fish_use_subcommand -a claude-teams -d 'Launch Claude teams'
complete -c cmux -n __fish_use_subcommand -a codex-teams -d 'Launch Codex teams'
complete -c cmux -n __fish_use_subcommand -a omo -d 'Launch opencode team'
complete -c cmux -n __fish_use_subcommand -a omx -d 'Launch omx team'
complete -c cmux -n __fish_use_subcommand -a omc -d 'Launch omc team'
complete -c cmux -n __fish_use_subcommand -a hooks -d 'Manage agent hooks'
complete -c cmux -n __fish_use_subcommand -a ping -d 'Ping the running app'
complete -c cmux -n __fish_use_subcommand -a version -d 'Print the cmux version'
complete -c cmux -n __fish_use_subcommand -a capabilities -d 'Print available RPC methods (JSON)'
complete -c cmux -n __fish_use_subcommand -a events -d 'Stream cmux events as NDJSON'
complete -c cmux -n __fish_use_subcommand -a auth -d 'Manage authentication'
complete -c cmux -n __fish_use_subcommand -a login -d 'Sign in (alias for auth login)'
complete -c cmux -n __fish_use_subcommand -a logout -d 'Sign out (alias for auth logout)'
complete -c cmux -n __fish_use_subcommand -a vm -d 'Manage cloud VMs (alias: cloud)'
complete -c cmux -n __fish_use_subcommand -a cloud -d 'Manage cloud VMs (alias of vm)'
complete -c cmux -n __fish_use_subcommand -a rpc -d 'Call a raw RPC method'
complete -c cmux -n __fish_use_subcommand -a identify -d 'Identify a workspace/surface/window'
complete -c cmux -n __fish_use_subcommand -a list-windows -d 'List windows'
complete -c cmux -n __fish_use_subcommand -a current-window -d 'Show the current window'
complete -c cmux -n __fish_use_subcommand -a new-window -d 'Open a new window'
complete -c cmux -n __fish_use_subcommand -a focus-window -d 'Focus a window'
complete -c cmux -n __fish_use_subcommand -a close-window -d 'Close a window'
complete -c cmux -n __fish_use_subcommand -a move-workspace-to-window -d 'Move a workspace to a window'
complete -c cmux -n __fish_use_subcommand -a reorder-workspace -d 'Reorder a single workspace'
complete -c cmux -n __fish_use_subcommand -a reorder-workspaces -d 'Reorder workspaces by explicit order'
complete -c cmux -n __fish_use_subcommand -a workspace-action -d 'Run a workspace action'
complete -c cmux -n __fish_use_subcommand -a move-tab-to-new-workspace -d 'Move a tab into a new workspace'
complete -c cmux -n __fish_use_subcommand -a list-workspaces -d 'List workspaces'
complete -c cmux -n __fish_use_subcommand -a new-workspace -d 'Create a new workspace'
complete -c cmux -n __fish_use_subcommand -a ssh -d 'Open an SSH workspace'
complete -c cmux -n __fish_use_subcommand -a ssh-session-list -d 'List SSH sessions'
complete -c cmux -n __fish_use_subcommand -a ssh-session-attach -d 'Attach to an SSH session'
complete -c cmux -n __fish_use_subcommand -a ssh-session-cleanup -d 'Clean up SSH sessions'
complete -c cmux -n __fish_use_subcommand -a remote-daemon-status -d 'Show remote daemon status'
complete -c cmux -n __fish_use_subcommand -a new-split -d 'Create a split (left/right/up/down)'
complete -c cmux -n __fish_use_subcommand -a list-panes -d 'List panes'
complete -c cmux -n __fish_use_subcommand -a list-pane-surfaces -d 'List surfaces within panes'
complete -c cmux -n __fish_use_subcommand -a tree -d 'Show the workspace/pane tree'
complete -c cmux -n __fish_use_subcommand -a top -d 'Show per-surface process usage'
complete -c cmux -n __fish_use_subcommand -a memory -d 'Show per-surface memory usage'
complete -c cmux -n __fish_use_subcommand -a focus-pane -d 'Focus a pane'
complete -c cmux -n __fish_use_subcommand -a new-pane -d 'Create a pane'
complete -c cmux -n __fish_use_subcommand -a new-surface -d 'Create a surface'
complete -c cmux -n __fish_use_subcommand -a close-surface -d 'Close a surface'
complete -c cmux -n __fish_use_subcommand -a move-surface -d 'Move a surface'
complete -c cmux -n __fish_use_subcommand -a split-off -d 'Split a surface off'
complete -c cmux -n __fish_use_subcommand -a reorder-surface -d 'Reorder a surface'
complete -c cmux -n __fish_use_subcommand -a tab-action -d 'Run a tab action'
complete -c cmux -n __fish_use_subcommand -a surface -d 'Manage surface resume metadata'
complete -c cmux -n __fish_use_subcommand -a rename-tab -d 'Rename a tab'
complete -c cmux -n __fish_use_subcommand -a drag-surface-to-split -d 'Drag a surface to a split'
complete -c cmux -n __fish_use_subcommand -a refresh-surfaces -d 'Refresh all surfaces'
complete -c cmux -n __fish_use_subcommand -a reload-config -d 'Reload Ghostty + cmux.json'
complete -c cmux -n __fish_use_subcommand -a surface-health -d 'Report surface health'
complete -c cmux -n __fish_use_subcommand -a debug-terminals -d 'Dump terminal debug info'
complete -c cmux -n __fish_use_subcommand -a trigger-flash -d 'Flash a surface'
complete -c cmux -n __fish_use_subcommand -a list-panels -d 'List panels'
complete -c cmux -n __fish_use_subcommand -a focus-panel -d 'Focus a panel'
complete -c cmux -n __fish_use_subcommand -a close-workspace -d 'Close a workspace'
complete -c cmux -n __fish_use_subcommand -a select-workspace -d 'Select a workspace'
complete -c cmux -n __fish_use_subcommand -a rename-workspace -d 'Rename a workspace'
complete -c cmux -n __fish_use_subcommand -a rename-window -d 'Rename a window'
complete -c cmux -n __fish_use_subcommand -a current-workspace -d 'Show the current workspace'
complete -c cmux -n __fish_use_subcommand -a read-screen -d 'Read surface screen contents'
complete -c cmux -n __fish_use_subcommand -a send -d 'Send text to a surface'
complete -c cmux -n __fish_use_subcommand -a send-key -d 'Send a key to a surface'
complete -c cmux -n __fish_use_subcommand -a send-panel -d 'Send text to a panel'
complete -c cmux -n __fish_use_subcommand -a send-key-panel -d 'Send a key to a panel'
complete -c cmux -n __fish_use_subcommand -a notify -d 'Post a notification'
complete -c cmux -n __fish_use_subcommand -a list-notifications -d 'List notifications'
complete -c cmux -n __fish_use_subcommand -a dismiss-notification -d 'Dismiss a notification'
complete -c cmux -n __fish_use_subcommand -a mark-notification-read -d 'Mark notification(s) read'
complete -c cmux -n __fish_use_subcommand -a open-notification -d 'Open a notification'
complete -c cmux -n __fish_use_subcommand -a jump-to-unread -d 'Jump to the next unread'
complete -c cmux -n __fish_use_subcommand -a clear-notifications -d 'Clear notifications'
complete -c cmux -n __fish_use_subcommand -a right-sidebar -d 'Control the right sidebar'
complete -c cmux -n __fish_use_subcommand -a set-status -d 'Set a status item'
complete -c cmux -n __fish_use_subcommand -a clear-status -d 'Clear a status item'
complete -c cmux -n __fish_use_subcommand -a list-status -d 'List status items'
complete -c cmux -n __fish_use_subcommand -a set-progress -d 'Set a progress value'
complete -c cmux -n __fish_use_subcommand -a clear-progress -d 'Clear progress'
complete -c cmux -n __fish_use_subcommand -a log -d 'Append a log message'
complete -c cmux -n __fish_use_subcommand -a clear-log -d 'Clear the log'
complete -c cmux -n __fish_use_subcommand -a list-log -d 'List log entries'
complete -c cmux -n __fish_use_subcommand -a sidebar-state -d 'Show sidebar state'
complete -c cmux -n __fish_use_subcommand -a set-app-focus -d 'Set app focus state'
complete -c cmux -n __fish_use_subcommand -a simulate-app-active -d 'Simulate the app being active'
complete -c cmux -n __fish_use_subcommand -a capture-pane -d 'Capture pane contents (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a resize-pane -d 'Resize a pane (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a pipe-pane -d 'Pipe pane output to a command'
complete -c cmux -n __fish_use_subcommand -a wait-for -d 'Wait for a signal (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a swap-pane -d 'Swap two panes (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a break-pane -d 'Break a pane out (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a join-pane -d 'Join a pane (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a next-window -d 'Focus the next window'
complete -c cmux -n __fish_use_subcommand -a previous-window -d 'Focus the previous window'
complete -c cmux -n __fish_use_subcommand -a last-window -d 'Focus the last window'
complete -c cmux -n __fish_use_subcommand -a last-pane -d 'Focus the last pane'
complete -c cmux -n __fish_use_subcommand -a find-window -d 'Find a window by query'
complete -c cmux -n __fish_use_subcommand -a clear-history -d 'Clear surface scrollback'
complete -c cmux -n __fish_use_subcommand -a set-hook -d 'Set/list/unset a hook'
complete -c cmux -n __fish_use_subcommand -a popup -d 'Open a popup'
complete -c cmux -n __fish_use_subcommand -a bind-key -d 'Bind a key (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a unbind-key -d 'Unbind a key (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a copy-mode -d 'Enter copy mode (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a set-buffer -d 'Set a paste buffer'
complete -c cmux -n __fish_use_subcommand -a list-buffers -d 'List paste buffers'
complete -c cmux -n __fish_use_subcommand -a paste-buffer -d 'Paste a buffer'
complete -c cmux -n __fish_use_subcommand -a respawn-pane -d 'Respawn a pane (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a display-message -d 'Display a message (tmux compat)'
complete -c cmux -n __fish_use_subcommand -a markdown -d 'Open a markdown file in a viewer'
complete -c cmux -n __fish_use_subcommand -a browser -d 'Browser automation commands'
complete -c cmux -n __fish_use_subcommand -a help -d 'Show help'

# ---------------------------------------------------------------------------
# Global options (used before a command)
# ---------------------------------------------------------------------------
complete -c cmux -n __fish_use_subcommand -l json                 -d 'Emit JSON output'
complete -c cmux -n __fish_use_subcommand -l password -x          -d 'Socket auth password'
complete -c cmux -n __fish_use_subcommand -l id-format -x -a 'refs uuids both' -d 'Handle output format'
complete -c cmux -n __fish_use_subcommand -s h -l help            -d 'Show help'
complete -c cmux -n __fish_use_subcommand -l version              -d 'Show version'

# ---------------------------------------------------------------------------
# Common context flags, applied broadly to the workspace/surface/pane commands.
# Over-offering a context flag on a command that ignores it is harmless and the
# vast majority of commands accept --workspace/--window.
# ---------------------------------------------------------------------------

# Commands that accept --workspace / --window (nearly all of them).
set -l cmux_ctx_cmds \
    open identify move-tab-to-new-workspace list-workspaces new-workspace ssh \
    ssh-session-list ssh-session-attach ssh-session-cleanup new-split list-panes \
    list-pane-surfaces tree top memory focus-pane new-pane new-surface close-surface \
    move-surface split-off reorder-surface tab-action surface rename-tab \
    drag-surface-to-split surface-health trigger-flash list-panels focus-panel \
    close-workspace select-workspace rename-workspace rename-window current-workspace \
    read-screen send send-key send-panel send-key-panel notify mark-notification-read \
    clear-notifications right-sidebar set-status clear-status list-status set-progress \
    clear-progress log clear-log list-log sidebar-state reorder-workspace \
    reorder-workspaces workspace-action move-workspace-to-window capture-pane resize-pane \
    pipe-pane swap-pane break-pane join-pane last-pane clear-history paste-buffer \
    respawn-pane markdown

for c in $cmux_ctx_cmds
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l workspace -x -d 'Workspace id|ref|index'
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l window    -x -d 'Window id|ref|index'
end

# Commands that accept --surface.
set -l cmux_surface_cmds \
    identify move-tab-to-new-workspace new-split list-pane-surfaces new-surface \
    close-surface move-surface split-off reorder-surface tab-action surface rename-tab \
    drag-surface-to-split read-screen send send-key notify mark-notification-read \
    capture-pane pipe-pane break-pane respawn-pane close-surface
for c in $cmux_surface_cmds
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l surface -x -d 'Surface id|ref|index'
end

# Commands that accept --pane.
set -l cmux_pane_cmds \
    new-split focus-pane ssh-session-attach move-surface tab-action resize-pane \
    swap-pane break-pane join-pane respawn-pane
for c in $cmux_pane_cmds
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l pane -x -d 'Pane id|ref|index'
end

# Commands that accept --panel.
set -l cmux_panel_cmds new-split focus-panel send-panel send-key-panel list-panels
for c in $cmux_panel_cmds
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l panel -x -d 'Panel id|ref|index'
end

# Commands that accept --focus <true|false> / --no-focus.
set -l cmux_focus_cmds \
    open new-workspace new-split new-pane new-surface move-surface split-off tab-action \
    reorder-surface drag-surface-to-split move-tab-to-new-workspace ssh swap-pane \
    break-pane join-pane markdown
for c in $cmux_focus_cmds
    complete -c cmux -n "__fish_seen_subcommand_from $c; and not __cmux_in_browser" -l focus -x -a 'true false' -d 'Focus the result'
end
complete -c cmux -n '__fish_seen_subcommand_from open ssh break-pane join-pane; and not __cmux_in_browser' -l no-focus -d 'Do not focus'

# ---------------------------------------------------------------------------
# Per-command flags and positional enums
# ---------------------------------------------------------------------------

# open
complete -c cmux -n '__fish_seen_subcommand_from open' -l id-format -x -a 'refs uuids both' -d 'Handle output format'

# new-split / split-off / drag-surface-to-split positional direction
complete -c cmux -n '__fish_seen_subcommand_from new-split split-off drag-surface-to-split; and not __cmux_in_browser' -a 'left right up down' -d Direction

# new-pane / new-surface
complete -c cmux -n '__fish_seen_subcommand_from new-pane new-surface' -l type      -x -a 'terminal browser' -d 'Surface type'
complete -c cmux -n '__fish_seen_subcommand_from new-pane'             -l direction  -x -a 'left right up down' -d Direction
complete -c cmux -n '__fish_seen_subcommand_from new-pane new-surface' -l url        -x -d URL

# new-workspace
complete -c cmux -n '__fish_seen_subcommand_from new-workspace' -l name        -x -d 'Workspace title'
complete -c cmux -n '__fish_seen_subcommand_from new-workspace' -l description -x -d 'Workspace description'
complete -c cmux -n '__fish_seen_subcommand_from new-workspace' -l cwd         -r -d 'Working directory'
complete -c cmux -n '__fish_seen_subcommand_from new-workspace' -l command     -x -d 'Initial command'
complete -c cmux -n '__fish_seen_subcommand_from new-workspace' -l layout      -x -d 'Layout JSON'

# tree / top / memory
complete -c cmux -n '__fish_seen_subcommand_from tree top memory; and not __cmux_in_browser' -l all -d 'Include all windows'
complete -c cmux -n '__fish_seen_subcommand_from top' -l processes -d 'Show processes'
complete -c cmux -n '__fish_seen_subcommand_from top' -l flat      -d 'Flat output'
complete -c cmux -n '__fish_seen_subcommand_from top' -l sort   -x -a 'cpu mem proc' -d 'Sort key'
complete -c cmux -n '__fish_seen_subcommand_from top' -l format -x -a 'tree tsv'     -d 'Output format'
complete -c cmux -n '__fish_seen_subcommand_from memory' -l groups -x -d 'Group count'

# reorder-* positional / index flags
complete -c cmux -n '__fish_seen_subcommand_from reorder-workspace reorder-surface move-surface' -l index  -x -d 'Target index'
complete -c cmux -n '__fish_seen_subcommand_from reorder-workspace reorder-surface move-surface' -l before -x -d 'Place before'
complete -c cmux -n '__fish_seen_subcommand_from reorder-workspace reorder-surface move-surface' -l after  -x -d 'Place after'
complete -c cmux -n '__fish_seen_subcommand_from reorder-workspace reorder-surface' -l dry-run -d 'Dry run'
complete -c cmux -n '__fish_seen_subcommand_from reorder-workspaces' -l order -x -d 'Comma-separated order'

# workspace-action / tab-action
complete -c cmux -n '__fish_seen_subcommand_from workspace-action tab-action' -l action -x -d 'Action name'
complete -c cmux -n '__fish_seen_subcommand_from workspace-action tab-action' -l title  -x -d Title
complete -c cmux -n '__fish_seen_subcommand_from workspace-action' -l color       -x -d 'Color name/#hex'
complete -c cmux -n '__fish_seen_subcommand_from workspace-action' -l description -x -d Description
complete -c cmux -n '__fish_seen_subcommand_from tab-action; and not __cmux_in_browser' -l tab -x -d 'Tab id|ref|index'
complete -c cmux -n '__fish_seen_subcommand_from tab-action' -l url -x -d URL

# rename-tab / move-tab-to-new-workspace tab handle
complete -c cmux -n '__fish_seen_subcommand_from rename-tab move-tab-to-new-workspace; and not __cmux_in_browser' -l tab -x -d 'Tab id|ref|index'
complete -c cmux -n '__fish_seen_subcommand_from move-tab-to-new-workspace' -l title -x -d Title

# ssh
complete -c cmux -n '__fish_seen_subcommand_from ssh' -l name       -x -d 'Workspace title'
complete -c cmux -n '__fish_seen_subcommand_from ssh' -l port       -x -d 'SSH port'
complete -c cmux -n '__fish_seen_subcommand_from ssh' -l identity   -r -d 'Identity file'
complete -c cmux -n '__fish_seen_subcommand_from ssh' -l ssh-option -x -d 'Extra ssh option'

# ssh-session-list / cleanup
complete -c cmux -n '__fish_seen_subcommand_from ssh-session-list ssh-session-cleanup' -l all-workspaces -d 'All workspaces'
complete -c cmux -n '__fish_seen_subcommand_from ssh-session-attach ssh-session-cleanup' -l session-id -x -d 'Session id'
complete -c cmux -n '__fish_seen_subcommand_from ssh-session-cleanup' -l all -d 'All sessions'
complete -c cmux -n '__fish_seen_subcommand_from ssh-session-attach' -l split -x -a 'left right up down' -d 'Split direction'

# remote-daemon-status
complete -c cmux -n '__fish_seen_subcommand_from remote-daemon-status' -l os   -x -a 'darwin linux' -d OS
complete -c cmux -n '__fish_seen_subcommand_from remote-daemon-status' -l arch -x -a 'arm64 amd64'   -d Arch

# focus-window / close-window / focus-pane / focus-panel handles
complete -c cmux -n '__fish_seen_subcommand_from focus-window close-window' -l window -x -d 'Window id|ref|index'

# notifications
complete -c cmux -n '__fish_seen_subcommand_from dismiss-notification mark-notification-read open-notification' -l id -x -d 'Notification uuid'
complete -c cmux -n '__fish_seen_subcommand_from dismiss-notification' -l all-read -d 'All read notifications'
complete -c cmux -n '__fish_seen_subcommand_from mark-notification-read' -l all -d 'All notifications'

# notify
complete -c cmux -n '__fish_seen_subcommand_from notify' -l title    -x -d Title
complete -c cmux -n '__fish_seen_subcommand_from notify' -l subtitle -x -d Subtitle
complete -c cmux -n '__fish_seen_subcommand_from notify' -l body     -x -d Body

# status / progress
complete -c cmux -n '__fish_seen_subcommand_from set-status' -l icon     -x -d Icon
complete -c cmux -n '__fish_seen_subcommand_from set-status' -l color    -x -d '#hex color'
complete -c cmux -n '__fish_seen_subcommand_from set-status' -l priority -x -d Priority
complete -c cmux -n '__fish_seen_subcommand_from set-progress' -l label  -x -d Label

# log
complete -c cmux -n '__fish_seen_subcommand_from log' -l level  -x -a 'debug info warn error' -d 'Log level'
complete -c cmux -n '__fish_seen_subcommand_from log' -l source -x -d 'Log source'
complete -c cmux -n '__fish_seen_subcommand_from list-log' -l limit -x -d Limit

# read-screen / capture-pane scrollback
complete -c cmux -n '__fish_seen_subcommand_from read-screen capture-pane; and not __cmux_in_browser' -l scrollback -d 'Include scrollback'
complete -c cmux -n '__fish_seen_subcommand_from read-screen capture-pane; and not __cmux_in_browser' -l lines -x -d 'Number of lines'

# right-sidebar positional modes
complete -c cmux -n '__fish_seen_subcommand_from right-sidebar' -a 'toggle show hide focus set mode files find vault sessions feed dock' -d 'Sidebar action'

# set-app-focus positional
complete -c cmux -n '__fish_seen_subcommand_from set-app-focus' -a 'active inactive clear' -d 'Focus state'

# resize-pane direction flags
complete -c cmux -n '__fish_seen_subcommand_from resize-pane' -s L -d 'Resize left'
complete -c cmux -n '__fish_seen_subcommand_from resize-pane' -s R -d 'Resize right'
complete -c cmux -n '__fish_seen_subcommand_from resize-pane' -s U -d 'Resize up'
complete -c cmux -n '__fish_seen_subcommand_from resize-pane' -s D -d 'Resize down'
complete -c cmux -n '__fish_seen_subcommand_from resize-pane' -l amount -x -d Amount
complete -c cmux -n '__fish_seen_subcommand_from swap-pane join-pane' -l target-pane -x -d 'Target pane id|ref|index'

# pipe-pane / respawn-pane / wait-for / find-window
complete -c cmux -n '__fish_seen_subcommand_from pipe-pane'    -l command -x -d 'Shell command'
complete -c cmux -n '__fish_seen_subcommand_from respawn-pane' -l command -x -d 'Command'
complete -c cmux -n '__fish_seen_subcommand_from wait-for'     -s S -l signal  -d 'Signal'
complete -c cmux -n '__fish_seen_subcommand_from wait-for'     -l timeout -x -d 'Timeout (s)'
complete -c cmux -n '__fish_seen_subcommand_from find-window'  -l content -d 'Search content'
complete -c cmux -n '__fish_seen_subcommand_from find-window'  -l select  -d 'Select match'

# set-hook / buffers / display-message
complete -c cmux -n '__fish_seen_subcommand_from set-hook' -l list  -d 'List hooks'
complete -c cmux -n '__fish_seen_subcommand_from set-hook' -l unset -x -d 'Unset event'
complete -c cmux -n '__fish_seen_subcommand_from set-buffer paste-buffer' -l name -x -d 'Buffer name'
complete -c cmux -n '__fish_seen_subcommand_from display-message' -s p -l print -d 'Print only'

# markdown
complete -c cmux -n '__fish_seen_subcommand_from markdown' -a open -d 'Open file'

# ---------------------------------------------------------------------------
# docs <topic>
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from docs' -a 'settings shortcuts api browser agents dock' -d 'Docs topic'

# ---------------------------------------------------------------------------
# settings [open|path|docs|<target>]
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from settings' -a 'open path docs' -d 'Settings command'
complete -c cmux -n '__fish_seen_subcommand_from settings' -a 'account app terminal sidebar-appearance automation browser browser-import global-hotkey keyboard-shortcuts shortcuts workspace-colors cmux-json json reset' -d 'Settings target'

# ---------------------------------------------------------------------------
# config <doctor|check|validate|path|paths|docs|documentation|reload>
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from config' -a 'doctor check validate path paths docs documentation reload' -d 'Config command'
complete -c cmux -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from doctor check validate' -l path -r -d 'Config file path'

# ---------------------------------------------------------------------------
# themes [list|set|clear]
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from themes; and not __fish_seen_subcommand_from list set clear' -a 'list set clear' -d 'Themes command'
complete -c cmux -n '__fish_seen_subcommand_from themes; and __fish_seen_subcommand_from set' -l light -x -a '(__cmux_themes)' -d 'Light theme'
complete -c cmux -n '__fish_seen_subcommand_from themes; and __fish_seen_subcommand_from set' -l dark  -x -a '(__cmux_themes)' -d 'Dark theme'
complete -c cmux -n '__fish_seen_subcommand_from themes; and __fish_seen_subcommand_from set' -a '(__cmux_themes)' -d Theme

# ---------------------------------------------------------------------------
# hooks setup|uninstall|feed|<agent>
# ---------------------------------------------------------------------------
set -l cmux_hook_agents codex grok opencode pi amp cursor gemini antigravity agy rovodev rovo hermes-agent copilot codebuddy factory qoder
complete -c cmux -n '__fish_seen_subcommand_from hooks; and not __fish_seen_subcommand_from setup uninstall feed' -a 'setup uninstall feed' -d 'Hook target'
complete -c cmux -n '__fish_seen_subcommand_from hooks; and not __fish_seen_subcommand_from setup uninstall feed' -a "$cmux_hook_agents" -d 'Agent'
complete -c cmux -n '__fish_seen_subcommand_from hooks; and __fish_seen_subcommand_from setup uninstall' -l agent -x -a "$cmux_hook_agents" -d Agent
complete -c cmux -n '__fish_seen_subcommand_from hooks; and __fish_seen_subcommand_from setup uninstall' -s y -l yes -d 'Skip confirmation'
complete -c cmux -n '__fish_seen_subcommand_from hooks; and __fish_seen_subcommand_from opencode' -l project -d 'Project scope'
complete -c cmux -n '__fish_seen_subcommand_from hooks; and __fish_seen_subcommand_from feed' -l source -x -a "$cmux_hook_agents" -d 'Source agent'
complete -c cmux -n '__fish_seen_subcommand_from hooks; and __fish_seen_subcommand_from feed' -l event  -x -d Event

# ---------------------------------------------------------------------------
# vm / cloud <new|ls|rm|exec|shell|attach|ssh|ssh-info>
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from vm cloud; and not __fish_seen_subcommand_from new ls rm exec shell attach ssh ssh-info' -a 'new ls rm exec shell attach ssh ssh-info' -d 'VM command'
complete -c cmux -n '__fish_seen_subcommand_from vm cloud; and __fish_seen_subcommand_from new' -l image    -x -d 'VM image template'
complete -c cmux -n '__fish_seen_subcommand_from vm cloud; and __fish_seen_subcommand_from new' -l provider -x -d 'VM provider'
complete -c cmux -n '__fish_seen_subcommand_from vm cloud; and __fish_seen_subcommand_from new' -s d -l detach -d 'Detach (print id and exit)'

# ---------------------------------------------------------------------------
# auth <status|login|logout>
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from auth; and not __fish_seen_subcommand_from status login logout' -a 'status login logout' -d 'Auth command'

# ---------------------------------------------------------------------------
# feed tui|clear
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from feed; and not __fish_seen_subcommand_from tui clear' -a 'tui clear' -d 'Feed command'
complete -c cmux -n '__fish_seen_subcommand_from feed; and __fish_seen_subcommand_from tui' -l opentui -d 'Force OpenTUI'
complete -c cmux -n '__fish_seen_subcommand_from feed; and __fish_seen_subcommand_from tui' -l legacy  -d 'Force legacy TUI'
complete -c cmux -n '__fish_seen_subcommand_from feed; and __fish_seen_subcommand_from clear' -s y -l yes -d 'Skip confirmation'

# ---------------------------------------------------------------------------
# feedback
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from feedback' -l email -x -d 'Contact email'
complete -c cmux -n '__fish_seen_subcommand_from feedback' -l body  -x -d 'Feedback body'
complete -c cmux -n '__fish_seen_subcommand_from feedback' -l image -r -d 'Attach image'

# ---------------------------------------------------------------------------
# events
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from events' -l after        -x -d 'Replay after seq'
complete -c cmux -n '__fish_seen_subcommand_from events' -l cursor-file  -r -d 'Cursor file'
complete -c cmux -n '__fish_seen_subcommand_from events' -l name         -x -d 'Filter by event name'
complete -c cmux -n '__fish_seen_subcommand_from events' -l category     -x -d 'Filter by category'
complete -c cmux -n '__fish_seen_subcommand_from events' -l reconnect    -d 'Reconnect forever'
complete -c cmux -n '__fish_seen_subcommand_from events' -l limit        -x -d 'Exit after n frames'
complete -c cmux -n '__fish_seen_subcommand_from events' -l no-ack       -d 'No subscription ack'
complete -c cmux -n '__fish_seen_subcommand_from events' -l no-heartbeat -d 'No heartbeats'

# ---------------------------------------------------------------------------
# surface resume <set|show|get|clear>
# ---------------------------------------------------------------------------
complete -c cmux -n '__fish_seen_subcommand_from surface; and not __cmux_in_browser; and not __fish_seen_subcommand_from resume' -a resume -d 'Resume metadata'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume; and not __fish_seen_subcommand_from set show get clear' -a 'set show get clear' -d 'Resume action'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l cwd           -r -d 'Working directory'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l name          -x -d 'Display name'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l kind          -x -d 'Binding kind'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l checkpoint    -x -d 'Checkpoint/session id'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l checkpoint-id -x -d 'Checkpoint id (precedence)'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l source        -x -d 'Binding source'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume' -l shell         -x -d 'Restore shell command'
complete -c cmux -n '__fish_seen_subcommand_from surface; and __fish_seen_subcommand_from resume show get' -l json -d 'JSON output'

# ===========================================================================
# browser <subcommand>
# ===========================================================================
complete -c cmux -n '__cmux_in_browser; and not __fish_seen_subcommand_from open open-split new disable enable status goto navigate back forward reload url get-url focus-webview is-webview-focused snapshot eval wait click dblclick hover focus check uncheck scroll-into-view type fill press key keydown keyup select scroll screenshot get is find frame dialog download profiles import cookies storage tab console errors highlight state addinitscript addscript addstyle identify' \
    -a 'open open-split new disable enable status goto navigate back forward reload url get-url focus-webview is-webview-focused snapshot eval wait click dblclick hover focus check uncheck scroll-into-view type fill press keydown keyup select scroll screenshot get is find frame dialog download profiles import cookies storage tab console errors highlight state addinitscript addscript addstyle identify' \
    -d 'Browser subcommand'

# browser --surface applies anywhere in the browser tree
complete -c cmux -n '__cmux_in_browser' -l surface -x -d 'Surface id|ref|index'

# browser open/open-split/new
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from open open-split new' -l workspace -x -d 'Workspace id|ref|index'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from open open-split new' -l window    -x -d 'Window id|ref|index'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from open open-split new' -l focus     -x -a 'true false' -d Focus

# --snapshot-after on mutating subcommands
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from goto navigate back forward reload click dblclick hover focus check uncheck scroll-into-view type fill press keydown keyup select scroll' -l snapshot-after -d 'Snapshot after action'

# browser snapshot
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from snapshot' -s i -l interactive -d 'Interactive only'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from snapshot' -l cursor    -d 'Include cursor'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from snapshot' -l compact   -d 'Compact output'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from snapshot' -l max-depth -x -d 'Max depth'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from snapshot' -l selector  -x -d 'CSS selector'

# browser eval / type / fill / press / select / *-selector commands
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from eval' -l script -x -d 'JS script'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from click dblclick hover focus check uncheck scroll-into-view type fill select is find scroll frame' -l selector -x -d 'CSS selector'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from type fill' -l text  -x -d Text
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from press keydown keyup' -l key -x -d Key
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from select' -l value -x -d Value
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from scroll' -l dx -x -d 'Delta X'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from scroll' -l dy -x -d 'Delta Y'

# browser wait
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l selector     -x -d 'CSS selector'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l text         -x -d Text
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l url-contains  -x -d 'URL contains'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l url          -x -d URL
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l load-state    -x -a 'interactive complete' -d 'Load state'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait' -l function      -x -d 'JS predicate'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait download' -l timeout-ms -x -d 'Timeout (ms)'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from wait download' -l timeout    -x -d 'Timeout (s)'

# browser screenshot / download
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from screenshot' -l out  -r -d 'Output path'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from screenshot' -l json -d 'JSON output'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from download' -l path -r -d 'Download path'

# browser get / is / find / dialog / profiles / cookies / storage / tab / console / errors / state
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from get'  -a 'url title text html value attr count box styles' -d 'Property'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from get'  -l attr -x -d 'Attribute name'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from get'  -l property -x -d 'CSS property'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from is'   -a 'visible enabled checked' -d Predicate
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from find' -a 'role text label placeholder alt title testid first last nth' -d 'Find by'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from find' -l name  -x -d Name
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from find' -l exact -d 'Exact match'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from find' -l index -x -d Index
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from frame'   -a main -d 'Main frame'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from dialog'  -a 'accept dismiss' -d 'Dialog action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from profiles' -a 'list add rename clear delete' -d 'Profiles action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from profiles' -l all   -d 'All profiles'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from profiles' -l force -d 'Force'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from cookies' -a 'get set clear' -d 'Cookies action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from storage' -a 'local session' -d 'Storage area'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from tab'     -a 'new list switch close' -d 'Tab action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from console' -a 'list clear' -d 'Console action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from errors'  -a 'list clear' -d 'Errors action'
complete -c cmux -n '__cmux_in_browser; and __fish_seen_subcommand_from state'   -a 'save load' -d 'State action'
