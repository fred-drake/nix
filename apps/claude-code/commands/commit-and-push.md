OBJECTIVE: Validate, commit, and push code changes with quality checks.

PRE-COMMIT VALIDATION:
1. RUN language-specific quality checks:
   - Go projects:
     * `just format` - Fix any formatting issues
     * `just lint` - Fix all linting errors
     * `just test` - Ensure all tests pass
     * `just vulncheck` - Ensure there are no known vulnerabilities
   - Rust projects:
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
     * `deadnix` - Fix all dead code errors

2. If ANY check fails:
   - Fix the issues
   - Re-run ALL checks until they pass, including checks you have previously run that were successful.
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