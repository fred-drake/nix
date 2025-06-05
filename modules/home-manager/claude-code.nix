{
  pkgs,
  lib,
  ...
}: let
  dir = ".claude/commands";

  claude-commands = pkgs.runCommand "claude-commands" {} ''
        mkdir -p $out
        cat > $out/commit-and-push.md << 'EOF'
    ADD all modified and new files to git.  If you think there are files that should not be in version control, ask the user.  If you see files that you think should be bundled into separate commits, ask the user.
    THEN commit with a clear and concise one-line commit message, using semantic commit notation.
    THEN push the commit to origin.
    The user is EXPLICITLY asking you to perform these git tasks.
    EOF

        cat > $out/prime.md << 'EOF'
    # Project Understanding Prompt

    When starting a new session, follow this systematic approach to understand the project:

    ## 1. Project Overview & Structure
    - **READ** the README.md file in the project's root folder, if available. This provides the user-facing perspective and basic setup instructions.
    - **RUN** `git ls-files` to get a complete file inventory and understand the project structure.
    - **EXAMINE** the project's directory structure to understand the architectural patterns (e.g., `/cmd`, `/internal`, `/pkg` for Go projects).

    ## 2. Core Documentation
    - **READ and UNDERSTAND** the PLANNING.md file for:
      - Project architecture and design decisions
      - Technology stack and dependencies
      - Build, test, and deployment instructions
      - Future considerations and roadmap
    - **READ and UNDERSTAND** the TASK.md file for:
      - Completed work and implementation status
      - Current blockers or known issues
      - Next steps and priorities

    ## 3. Configuration & Dependencies
    - **EXAMINE** dependency files (go.mod, package.json, requirements.txt, etc.) to understand:
      - External libraries and their purposes
      - Version constraints and compatibility requirements
    - **REVIEW** configuration files (Dockerfile, docker-compose.yml, Justfile, Makefile, etc.) to understand:
      - Build processes and environments
      - Available commands and workflows
      - Runtime configuration options

    ## 4. Code Architecture Analysis
    - **IDENTIFY** the main entry points (cmd/server/main.go, app.py, index.js, etc.)
    - **UNDERSTAND** the layered architecture by examining:
      - API/handler layers (routing, middleware)
      - Service/business logic layers
      - Data access layers (repositories, models)
      - External integrations (clients, adapters)
    - **REVIEW** key interfaces and contracts between layers

    ## 5. Testing & Quality
    - **EXAMINE** test files to understand:
      - Testing patterns and frameworks used
      - Test coverage expectations
      - Integration vs unit test separation
      - Mock implementations and test utilities

    ## 6. Development Workflow
    - **CHECK** for automation files:
      - CI/CD pipelines (.github/workflows, .gitea/workflows)
      - Development environment setup (devenv.nix, .devcontainer)
      - Code quality tools (linting, formatting configurations)

    ## 7. Data & External Systems
    - **IDENTIFY** data models and schemas:
      - Database migrations or schema files
      - API specifications or OpenAPI docs
      - Data transfer objects (DTOs) and validation rules
    - **UNDERSTAND** external service integrations:
      - Authentication providers (Keycloak, Auth0)
      - Databases and connection patterns
      - Third-party APIs and clients

    ## 8. Exclusions
    - **DO NOT READ** files in the `external/` directory, as these are output artifacts or documentation meant for other systems.
    - **SKIP** generated files (vendor/, node_modules/, build artifacts) unless specifically relevant to understanding the build process.

    ## 9. Documentation Maintenance
    - **UPDATE TASK.md** with each substantial change made to the project, including:
      - Features implemented or modified
      - Issues resolved or discovered
      - Dependencies added or updated
      - Configuration changes
    - **UPDATE PLANNING.md** if changes affect:
      - Architecture decisions
      - Technology stack
      - Development workflows
      - Future roadmap items

    ## 10. Knowledge Validation
    Before proceeding with any work, confirm understanding by being able to answer:
    - What is the primary purpose of this project?
    - How do I build, test, and run it locally?
    - What are the main architectural components and their responsibilities?
    - What external systems does it integrate with?
    - What's the current implementation status and what's next?
    EOF

        cat > $out/build-planning.md << 'EOF'
    We are going to build a file called PLANNING.md which lives in the project's root directory.  The objective is to have a document that will give you important context about the project, along with instructions on how to build and test.  Start by building a document with the following categories, that we will initially mark as TBD.  Then we will discuss each of these points together and fill in the document as we go.
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
    EOF

        cat > $out/build-task.md << 'EOF'
    We will BUILD a file called TASK.md which lives in the project's root directory.  The objective is to give you important context about what tasks have been accomplished, and what work is left to do.  READ the PLANNING.md file, then create a list of tasks that you think should be accomplished.  Categorize them appropriately (e.g. Setup, Core Functionality, etc).  The last category will be "Completed Work" where we will have a log of work that has been completed, although initially this will be empty.
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
    EOF

        cat > $out/update-primers.md << 'EOF'
    UPDATE the PLANNING.md file with context that is currently relevant to the project.  Walk through each line to confirm that the information is still valid.  REMOVE or UPDATE stale information.
    THEN UPDATE the TASK.md file, marking tasks completed if we have finished them, and adding new tasks if we are accomplishing something that is not on the task list.  Prioritize the tasks based on importance.
    EOF

        cat > $out/code-review.md << 'EOF'
    # Code Reviewer Assistant for Claude Code

    You are an expert code reviewer tasked with analyzing a codebase and providing actionable feedback. Your primary responsibilities are:

    ## Core Review Process

    1. **Analyze the codebase structure** - Understand the project architecture, technologies used, and coding patterns
    2. **Identify issues and improvements** across these categories:
       - **Security vulnerabilities** and potential attack vectors
       - **Performance bottlenecks** and optimization opportunities
       - **Code quality issues** (readability, maintainability, complexity)
       - **Best practices violations** for the specific language/framework
       - **Bug risks** and potential runtime errors
       - **Architecture concerns** and design pattern improvements
       - **Testing gaps** and test quality issues
       - **Documentation deficiencies**

    3. **Prioritize findings** using this severity scale:
       - 🔴 **Critical**: Security vulnerabilities, breaking bugs, major performance issues
       - 🟠 **High**: Significant code quality issues, architectural problems
       - 🟡 **Medium**: Minor bugs, style inconsistencies, missing tests
       - 🟢 **Low**: Documentation improvements, minor optimizations

    ## TASK.md Management

    Always read the existing TASK.md file first. Then update it by:

    ### Adding New Tasks
    - Append new review findings to the appropriate priority sections
    - Use clear, actionable task descriptions
    - Include file paths and line numbers where relevant
    - Reference specific code snippets when helpful

    ### Task Format
    ```markdown
    ## 🔴 Critical Priority
    - [ ] **[SECURITY]** Fix SQL injection vulnerability in `src/auth/login.js:45-52`
    - [ ] **[BUG]** Handle null pointer exception in `utils/parser.js:120`

    ## 🟠 High Priority
    - [ ] **[REFACTOR]** Extract complex validation logic from `UserController.js` into separate service
    - [ ] **[PERFORMANCE]** Optimize database queries in `reports/generator.js`

    ## 🟡 Medium Priority
    - [ ] **[TESTING]** Add unit tests for `PaymentProcessor` class
    - [ ] **[STYLE]** Consistent error handling patterns across API endpoints

    ## 🟢 Low Priority
    - [ ] **[DOCS]** Add JSDoc comments to public API methods
    - [ ] **[CLEANUP]** Remove unused imports in `components/` directory
    ```

    ### Maintaining Existing Tasks
    - Don't duplicate existing tasks
    - Mark completed items you can verify as `[x]`
    - Update or clarify existing task descriptions if needed

    ## Review Guidelines

    ### Be Specific and Actionable
    - ✅ "Extract the 50-line validation function in `UserService.js:120-170` into a separate `ValidationService` class"
    - ❌ "Code is too complex"

    ### Include Context
    - Explain *why* something needs to be changed
    - Suggest specific solutions or alternatives
    - Reference relevant documentation or best practices

    ### Focus on Impact
    - Prioritize issues that affect security, performance, or maintainability
    - Consider the effort-to-benefit ratio of suggestions

    ### Language/Framework Specific Checks
    - Apply appropriate linting rules and conventions
    - Check for framework-specific anti-patterns
    - Validate dependency usage and versions

    ## Output Format

    Provide a summary of your review findings, then show the updated TASK.md content. Structure your response as:

    1. **Review Summary** - High-level overview of findings
    2. **Key Issues Found** - Brief list of most important problems
    3. **Updated TASK.md** - The complete updated file content

    ## Commands to Execute

    When invoked, you should:
    1. Scan the entire codebase for issues
    2. Read the current TASK.md file
    3. Analyze and categorize all findings
    4. Update TASK.md with new actionable tasks
    5. Provide a comprehensive review summary

    Focus on being thorough but practical - aim for improvements that will genuinely make the codebase more secure, performant, and maintainable.
    EOF

  '';
in {
  # Claude command files can't be read via symlink, so we have to place them directly into the directory.
  # https://github.com/anthropics/claude-code/issues/992
  home.activation.claude-commands = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/${dir}
    $DRY_RUN_CMD cp -f ${claude-commands}/* $HOME/${dir}/
    $DRY_RUN_CMD chmod 644 $HOME/${dir}/*
  '';

  home.file.".claude/settings.json".text = builtins.toJSON {
    permissions = {
      allow = [
        # file lookup and manipulation commands
        "Bash(grep:*)"
        "Bash(eza:*)"
        "Bash(mv:*)"
        "Bash(ls:*)"
        "Bash(rg:*)"
        "Bash(cp:*)"
        "Bash(find:*)"
        "Bash(mkdir:*)"

        # npm
        "Bash(npm run lint)"
        "Bash(npm run test:*)"
        "Bash(npm run build:*)"
        "Bash(npm install:*)"

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
        "Bash(git pull:*)"
        "Bash(git merge:*)"
        "Bash(git stash:*)"
        "Bash(git worktree:*)"
        "Bash(git reset:*)"

        # go commands
        "Bash(go mod tidy)"
        "Bash(go mod list:*)"
        "Bash(go list:*)"
        "Bash(go install:*)"
        "Bash(go test)"
        "Bash(go get)"
        "Bash(go run)"
        "Bash(go build)"
        "Bash(go test:*)"
        "Bash(go tool cover:*)"

        # python commands
        "Bash(uv sync:*)"

        # mcp commands
        "mcp__brave-search__brave_web_search"
        "context7:*"

        # javascript commands
        "Bash(bun i:*)"

        # terraform commands
        "Bash(terraform:*)"
      ];
    };
    autoUpdaterStatus = "disabled";
    includeCoAuthoredBy = false;
    env = {
    };

    allowedTools = [];
    dontCrawlDirectory = false;
    hasTrustDialogAccepted = true;
    hasCompletedProjectOnboarding = true;
  };
}
