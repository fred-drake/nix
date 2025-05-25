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
    READ and UNDERSTAND the README.md file in the project's root folder, if it is available.  This will help you understand the project from ther user's perspective.
    THEN run git ls-files to understand the files in this project.
    THEN READ and UNDERSTAND the PLANNING.md file in the project's root folder, if it is available.  This will give you important context about the project, and instructions on how to build and test.
    THEN READ and UNDERSTAND the TASK.md file in the project's root folder, if it is available.  This will give you important context about what tasks have been accomplished, and what work is left to do, to the best of our knowledge.
    UPDATE the PLANNING.md and TASK.md files with each change that you make to the project.  This is important, because it will give you context on future sessions.
    DO NOT READ any files that are in the project's external/ directory.  Those are files intended to be used elsewhere and either repeat information or would adversely affect your ability to understand the project.
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

        cat > $out/update-primers.md << 'EOF'
    UPDATE the PLANNING.md file with context that is currently relevant to the project.  Walk through each line to confirm that the information is still valid.  REMOVE or UPDATE stale information.
    If the file does not exist, CREATE it and populate it with valid information, including:
        - Project Overview
        - Architecture
          - Core components (API, Data, Service layers, configuration, etc)
          - Data Model, if the project has a database component
        - API endpoints, if the project exposes endpoints to be consumed
        - Technology stack (Language, frameworks, etc)
        - Project structure
        - Testing strategy, if the project uses unit or integration testing
        - Development commands (to build,Data Model, if the project has a database component
        - API endpoints, if the project exposes endpoints to be consumed
        - Technology stack (Language, frameworks, etc)
        - Project structure
        - Testing strategy, if the project uses unit or integration tests.
        - Development commands (for building, running, etc).
        - Environment setup (how the development environment is currently set up for the project)
        - Development guidelines (rules to follow when modifying the project)
        - Security considerations (things to keep in mind that are security-focused when modifying the project)
        - Future considerations (things that we may not be adding right away but would be candidates for future versions)

    THEN UPDATE the TASK.md file, marking tasks completed if we have finished them, and adding new tasks if we are accomplishing something that is not on the task list.  Prioritize the tasks based on importance.  If the TASK.md file does not exist, CREATE it.
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
        # file lookups
        "Bash(grep:*)"
        "Bash(ls:*)"
        "Bash(rg:*)"
        "Bash(mkdir:*)"

        # npm
        "Bash(npm run lint)"
        "Bash(npm run test:*)"

        # non-intrusive just targets
        "Bash(just build)"
        "Bash(just test)"
        "Bash(just integration-test)"
        "Bash(just lint)"
        "Bash(just deps)"

        # git commands
        "Bash(git add:*)"
        "Bash(git commit:*)"
        "Bash(git push:*)"
        "Bash(git show:*)"

        # go commands
        "Bash(go mod tidy)"
        "Bash(go mod list:*)"
        "Bash(go list:*)"
        "Bash(go install:*)"
        "Bash(go test)"
        "Bash(go get)"
        "Bash(go test:*)"
        "Bash(go tool cover:*)"

        # mcp commands
        "mcp__brave-search__brave_web_search"
        "context7:*"
      ];
    };
    autoUpdaterStatus = "disabled";
    includeCoAuthoredBy = false;
    env = {
    };
  };
}
