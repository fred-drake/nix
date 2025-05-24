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
    THEN commit with a clear and concise one-line commit message, using semantic commit notation. DO NOT advertise Claude Code in any way.
    THEN push the commit to origin.
    EOF

        cat > $out/prime.md << 'EOF'
    READ the README.md file if it exists, to give you a user-level overview of this project.
    THEN run git ls-files to understand the files in this project.
    THEN if a specs/ directory exists, read ALL files inside that directory, to get a deeper understanding of the specifications.
    THEN if an ai_docs/ directory exists, read ALL files inside that directory, to understand development and execution rules for this project.
    EOF
  '';
in {
  home.activation.claude-commands = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/${dir}
    $DRY_RUN_CMD cp -f ${claude-commands}/* $HOME/${dir}/
    $DRY_RUN_CMD chmod 644 $HOME/${dir}/*
  '';

  home.file.".claude/settings.json".text = builtins.toJSON {
    permissions = {
      allow = ["Bash(npm run lint)" "Bash(npm run test:*)" "Bash(grep:*)" "Bash(ls:*)" "Bash(just build)" "Bash(just test)"];
    };
    autoUpdaterStatus = "disabled";
    env = {
    };
  };
}
