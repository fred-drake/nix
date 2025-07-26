Using the gitea MCP, look up issue #$ARGUMENTS for this project and return a JSON list containing only the names of all labels currently set on this issue. The output should be a simple JSON array of label names, like ["bug", "enhancement", "priority-high"].

We do not want ANY output other than our JSON array.  Otherwise, we will not be able to properly parse your output.
