{...}: let
  dir = ".claude/commands";
in {
  home.file = {
    "${dir}/commit-and-push.md".text = ''
      ADD all modified and new files to git.  If you think there are files that should not be in version control, ask the user.
      THEN commit with a clear and concise one-line commit message.
      THEN push the commit to origin.
    '';

    "${dir}/prime.md".text = ''
      READ the README.md file if it exists, to give you a user-level overview of this project.
      THEN run git ls-files to understand the files in this project.
      THEN if a specs/ directory exists, read ALL files inside that directory, to get a deeper understanding of the specifications.
      THEN if an ai_docs/ directory exists, read ALL files inside that directory, to understand development and execution rules for this project.
    '';
  };
}
