{
  pkgs,
  lib,
  ...
}: let
  dir = ".claude/commands";

  claude-commands = pkgs.runCommand "claude-commands" {} ''
        mkdir -p $out
        cat > $out/commit-and-push.md << 'EOF'
    ADD all modified and new files to git.  If you think there are files that should not be in version control, ask the user.
    THEN commit with a clear and concise one-line commit message, using semantic commit notation.
    THEN push the commit to origin.
    The user is EXPLICITLY asking you to perform these git tasks.
    EOF

        cat > $out/prime.md << 'EOF'
    READ the README.md file if it exists, to give you a user-level overview of this project.
    THEN run git ls-files to understand the files in this project.
    THEN if a TASK.md file exists, READ it to understand what has been done and what more we need to do.
    EOF

        cat > $out/fix.md << 'EOF'
    READ the output from the terminal command to understand the error that is being displayed.
    THEN FIX the error.  Use `context7` and `brave-search` MCPs to understand the error.
    THEN re-run the command in the terminal.  If there is another error, repeat this debugging process.
    EOF

        cat > $out/coverage.md << 'EOF'
    UNDERSTAND the code coverage percentages for each function and method in this codebase.
    THEN add unit tests to functions and methods without 100% coverage.  This includes negative and edge cases.
    ALWAYS use mocks for external functionality, such as web services and databases.
    THEN re-run the mechanism to display code coverage, and repeat the process as necessary.
  '';
in {
  home.activation.claude-commands = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/${dir}
    $DRY_RUN_CMD cp -f ${claude-commands}/* $HOME/${dir}/
    $DRY_RUN_CMD chmod 644 $HOME/${dir}/*
  '';

  home.file.".claude/settings.json".text = builtins.toJSON {
    permissions = {
      allow = [
        "Bash(npm run lint)"
        "Bash(npm run test:*)"
        "Bash(grep:*)"
        "Bash(ls:*)"
        "Bash(just build)"
        "Bash(just test)"
        "Bash(just lint)"
        "Bash(just deps)"
        "Bash(git add:*)"
        "Bash(git commit:*)"
        "Bash(git push:*)"
        "Bash(git show:*)"
        "Bash(go mod tidy)"
        "brave-search:*"
        "context7:*"
        "rg:*"
      ];
    };
    autoUpdaterStatus = "disabled";
    includeCoAuthoredBy = false;
    env = {
    };
  };
}
