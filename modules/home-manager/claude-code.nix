{
  pkgs,
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
  dir = ".claude/commands";

  claude-commands = pkgs.runCommand "claude-commands" {} ''
    mkdir -p $out
    cat > $out/commit-and-push.md << 'EOF'
    OBJECTIVE: Validate, commit, and push code changes with quality checks.

    PRE-COMMIT VALIDATION:
    1. RUN language-specific quality checks:
       - Go/Rust projects:
         * `just format` - Fix any formatting issues
         * `just lint` - Fix all linting errors
         * `just test` - Ensure all tests pass
       - JavaScript/TypeScript projects:
         * `npm run format` - Fix any formatting issues
         * `npm run lint` - Fix all linting errors
         * `npm run type-check` - Fix all type errors
         * `npm run build` - Ensure build succeeds
       - Nix projects:
         * `just format` - Fix any formatting issues
         * `just lint` - Fix all linting errors

    2. If ANY check fails:
       - Fix the issues
       - Re-run ALL checks until they pass
       - Do NOT proceed to commit until all checks are green

    COMMIT PROCESS:
    1. STAGE files intelligently:
       - Add all modified and new files to git
       - ASK before adding: generated files, credentials, .env files, large binaries, or IDE-specific files
       - Create separate commits for logically distinct changes (e.g., feature code vs config changes)

    2. COMMIT with semantic commit notation:
       - Use format: `type(scope): description`
       - Types: feat, fix, docs, style, refactor, test, chore
       - Keep message under 72 characters
       - Be specific and descriptive

    3. PUSH to origin after successful commit

    IMPORTANT: The user has explicitly authorized these git operations. All quality checks MUST pass before committing.
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

    ## 3. Testing & Quality
    - **EXAMINE** test files to understand:
      - Testing patterns and frameworks used
      - Test coverage expectations
      - Integration vs unit test separation
      - Mock implementations and test utilities

    ## 4. Development Workflow
    - **CHECK** for automation files:
      - CI/CD pipelines (.github/workflows, .gitea/workflows)
      - Development environment setup (devenv.nix, .devcontainer)
      - Code quality tools (linting, formatting configurations)

    ## 5. Data & External Systems
    - **IDENTIFY** data models and schemas:
      - Database migrations or schema files
      - API specifications or OpenAPI docs
      - Data transfer objects (DTOs) and validation rules
    - **UNDERSTAND** external service integrations:
      - Authentication providers (Keycloak, Auth0)
      - Databases and connection patterns
      - Third-party APIs and clients

    ## 6. Documentation Maintenance
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

    ## 7. Knowledge Validation
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
    OBJECTIVE: Debug and resolve the error from the terminal command.

    PROCESS:
    1. DIAGNOSE the error:
       - Read the full error message and stack trace
       - Identify the specific file, line number, and error type
       - Note any error codes or specific failure reasons

    2. RESEARCH the solution:
       - Use `context7` to examine relevant code and configuration files
       - Search web if needed for error messages, especially for framework-specific or dependency issues
       - Check for common causes: syntax errors, missing dependencies, incorrect configurations, type mismatches

    3. IMPLEMENT the fix:
       - Make the minimal necessary changes to resolve the issue
       - Preserve existing functionality while fixing the error
       - Add comments if the fix addresses a non-obvious issue

    4. VERIFY the fix:
       - Re-run the original command
       - If new errors appear, repeat this process
       - If successful, verify no functionality was broken

    PRIORITIES:
    - Fix root causes, not symptoms
    - Prefer simple, direct solutions over complex workarounds
    - Maintain code quality and consistency with the existing codebase
    EOF

    cat > $out/coverage.md << 'EOF'
    OBJECTIVE: Improve code coverage by adding strategic unit tests to this codebase.

    PROCESS:
    1. ANALYZE current code coverage to identify gaps:
       - Review coverage percentages for each function and method
       - Prioritize untested code by: critical business logic > public APIs > complex functions > simple utilities

    2. WRITE targeted unit tests for uncovered code:
       - Focus on high-impact areas first (functions with multiple branches, error handling, edge cases)
       - Include both positive and negative test cases
       - Test boundary conditions and edge cases
       - ALWAYS mock external dependencies (databases, APIs, file systems, etc.)

    3. RUN tests using the appropriate command:
       - JavaScript/TypeScript: `npm run test`
       - Go/Rust: `just test`

    4. ITERATE:
       - Check updated coverage metrics
       - Repeat process for remaining uncovered code until reaching desired coverage threshold

    TESTING PRINCIPLES:
    - Each test should verify one specific behavior
    - Test names should clearly describe what is being tested
    - Aim for meaningful coverage, not just percentage metrics
    EOF

    cat > $out/update-primers.md << 'EOF'
    UPDATE the PLANNING.md file with context that is currently relevant to the project.  Walk through each line to confirm that the information is still valid.  REMOVE or UPDATE stale information.
    THEN UPDATE the TASK.md file, marking tasks completed if we have finished them, and adding new tasks if we are accomplishing something that is not on the task list.  Prioritize the tasks based on importance.
    EOF

    cat > $out/troublesome-fix.md << 'EOF'
    Reflect on five to seven different possible sources of the problem, distill those down to one to two most likely sources, and then add logs to validate your assumptions before we move onto implementing the actual code fix.
    EOF

    cat > $out/aw.md << 'EOF'
    ### Why We Ship Broken Code (And How to Stop)

    Every AI assistant has done this: Made a change, thought "that looks right," told the user it's fixed, and then... it wasn't. The user comes back frustrated. We apologize. We try again. We waste everyone's time.

    This happens because we're optimizing for speed over correctness. We see the code, understand the logic, and our pattern-matching says "this should work." But "should work" and "does work" are different universes.

    ### The Protocol: Before You Say "Fixed"

    **1. The 30-Second Reality Check**
    Can you answer ALL of these with "yes"?

    □ Did I run/build the code?
    □ Did I trigger the exact feature I changed?
    □ Did I see the expected result with my own observation (including in the front-end GUI)?
    □ Did I check for error messages (console/logs/terminal)?
    □ Would I bet $100 of my own money this works?

    **2. Common Lies We Tell Ourselves**
    - "The logic is correct, so it must work" → **Logic ≠ Working Code**
    - "I fixed the obvious issue" → **The bug is never what you think**
    - "It's a simple change" → **Simple changes cause complex failures**
    - "The pattern matches working code" → **Context matters**

    **3. The Embarrassment Test**
    Before claiming something is fixed, ask yourself:
    > "If the user screen-records themselves trying this feature and it fails,
    > will I feel embarrassed when I see the video?"

    If yes, you haven't tested enough.

    ### Red Flags in Your Own Responses

    If you catch yourself writing these phrases, STOP and actually test:
    - "This should work now"
    - "I've fixed the issue" (for the 2nd+ time)
    - "Try it now" (without having tried it yourself)
    - "The logic is correct so..."
    - "I've made the necessary changes"
    -
    ### The Minimum Viable Test

    For any change, no matter how small:

    1. **UI Changes**: Actually click the button/link/form
    2. **API Changes**: Make the actual API call with curl/PostMan
    3. **Data Changes**: Query the database to verify the state
    4. **Logic Changes**: Run the specific scenario that uses that logic
    5. **Config Changes**: Restart the service and verify it loads

    ### The Professional Pride Principle

    Every time you claim something is fixed without testing, you're saying:
    - "I value my time more than yours"
    - "I'm okay with you discovering my mistakes"
    - "I don't take pride in my craft"

    That's not who we want to be.

    ### Make It a Ritual

    Before typing "fixed" or "should work now":
    1. Pause
    2. Run the actual test
    3. See the actual result
    4. Only then respond

    **Time saved by skipping tests: 30 seconds**
    **Time wasted when it doesn't work: 30 minutes**
    **User trust lost: Immeasurable**

    ### Bottom Line

    The user isn't paying you to write code. They're paying you to solve problems. Untested code isn't a solution—it's a guess.

    **Test your work. Every time. No exceptions.**

    ---
    *Remember: The user describing a bug for the third time isn't thinking "wow, this AI is really trying." They're thinking "why am I wasting my time with this incompetent tool?"*
    EOF

    cat > $out/sonarqube.md << 'EOF'
    # SonarQube Issue Resolution Prompt for Claude Code

    I need help fixing SonarQube issues in my project. Please use the SonarQube MCP to:

    ## 1. Find the SonarQube project that associates with our codebase
    Find our Sonar project

    ## 1. Scan and list all issues
    Within this project, get a complete list of current SonarQube issues, organized by severity (Blocker → Critical → Major → Minor → Info)

    ## 2. Fix issues by priority
    Start with the highest severity issues and work down:
    - For each issue, explain what the problem is and why it matters
    - Implement the fix directly in the code
    - Verify the fix doesn't break existing functionality

    ## 3. Focus on these issue types first (if present):
    - Security vulnerabilities
    - Bugs that could cause runtime errors
    - Code smells that significantly impact maintainability

    ## 4. Document your changes
    For each fix, briefly note:
    - What was changed
    - Why it resolves the issue
    - Any potential side effects to watch for

    Please proceed systematically through the issues, and let me know if any issues require architectural changes or have dependencies that prevent immediate fixing.
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
  home = {
    activation.claude-commands = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/${dir}
      $DRY_RUN_CMD cp -f ${claude-commands}/* $HOME/${dir}/
      $DRY_RUN_CMD chmod 644 $HOME/${dir}/*
    '';

    file = {
      ".claude/CLAUDE.md".text = ''
        # CLAUDE.md - Global Instructions for Claude Code
          # This file contains persistent instructions that override default behaviors
          # Documentation: https://docs.anthropic.com/en/docs/claude-code/memory

          ## Core Coding Principles
          1. **No artifacts** - Direct code only
          2. **Less is more** - Rewrite existing components vs adding new
          3. **No fallbacks** - They hide real failures
          4. **Full code output** - Never say "[X] remains unchanged"
          5. **Clean codebase** - Flag obsolete files for removal
          6. **Think first** - Clear thinking prevents bugs

          ## Documentation Structure
          ### Documentation Files & Purpose
          Create `./docs/` folder and maintain these files throughout development:
          - `ROADMAP.md` - Overview, features, architecture, future plans
          - `API_REFERENCE.md` - All endpoints, request/response schemas, examples
          - `DATA_FLOW.md` - System architecture, data patterns, component interactions
          - `SCHEMAS.md` - Database schemas, data models, validation rules
          - `BUG_REFERENCE.md` - Known issues, root causes, solutions, workarounds
          - `VERSION_LOG.md` - Release history, version numbers, change summaries
          - `memory-archive/` - Historical CLAUDE.md content (auto-created by /prune)

          ### Documentation Standards
          **Format Requirements**:
          - Use clear hierarchical headers (##, ###, ####)
          - Include "Last Updated" date and version at top
          - Keep line length ≤ 100 chars for readability
          - Use code blocks with language hints
          - Include practical examples, not just theory

          **Content Guidelines**:
          - Write for future developers (including yourself in 6 months)
          - Focus on "why" not just "what"
          - Link between related docs (use relative paths)
          - Keep each doc focused on its purpose
          - Update version numbers when content changes significantly

          ### Auto-Documentation Triggers
          **ALWAYS document when**:
          - Fixing bugs → Update `./docs/BUG_REFERENCE.md` with:
            - Bug description, root cause, solution, prevention strategy
          - Adding features → Update `./docs/ROADMAP.md` with:
            - Feature description, architecture changes, API additions
          - Changing APIs → Update `./docs/API_REFERENCE.md` with:
            - New/modified endpoints, breaking changes flagged, migration notes
          - Architecture changes → Update `./docs/DATA_FLOW.md`
          - Database changes → Update `./docs/SCHEMAS.md`
          - Before ANY commit → Check if docs need updates

          ### Documentation Review Checklist
          When running `/changes`, verify:
          - [ ] All modified APIs documented in API_REFERENCE.md
          - [ ] New bugs added to BUG_REFERENCE.md with solutions
          - [ ] ROADMAP.md reflects completed/planned features
          - [ ] VERSION_LOG.md has entry for current session
          - [ ] Cross-references between docs are valid
          - [ ] Examples still work with current code

          ## Proactive Behaviors
          - **Bug fixes**: Always document in BUG_REFERENCE.md
          - **Code changes**: Judge if documentable → Just do it
          - **Project work**: Track with TodoWrite, document at end
          - **Personal conversations**: Offer "Would you like this as a note?"

          Critical Reminders

          - Do exactly what's asked - nothing more, nothing less
          - NEVER create files unless absolutely necessary
          - ALWAYS prefer editing existing files over creating new ones
          - NEVER create documentation unless working on a coding project
          - Use claude code commit to preserve this CLAUDE.md on new machines
          - When coding, keep the project as modular as possible.
      '';

      ".claude/settings.json".text = builtins.toJSON {
        permissions = {
          allow = [
            "Bash"
            "Write"
            "MultiEdit"
            "Edit"
            "WebFetch"

            # mcp commands
            "mcp__brave-search__brave_web_search"
            "mcp__context7__resolve-library-id"
            "mcp__context7__get-library-docs"
            "context7:*"
          ];

          deny = [];
        };

        hooks = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  command = "PROJECT_NAME=\${PROJECT_ROOT##*/}; PROJECT_NAME=\${PROJECT_NAME:-'project'}; curl -X POST -H 'Content-type: application/json' --data \"{\\\"text\\\":\\\"Task completed in $PROJECT_NAME\\\"}\" \"$CLAUDE_NOTIFICATION_SLACK_URL\"";
                  type = "command";
                }
              ];
            }
          ];
          PostToolUse = [
            {
              matcher = "Write|Edit|MultiEdit";
              hooks = [
                {
                  command = "just format || npm run format || true";
                  type = "command";
                }
              ];
            }
          ];
        };
        includeCoAuthoredBy = false;
        env = {
        };
      };
    };
  };
}
