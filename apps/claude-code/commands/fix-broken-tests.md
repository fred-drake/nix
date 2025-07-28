We are going to run a loop where the coverage analyzer sub agent will execute commands to run checks on this project, assess the problems with the failing tests, and suggest solutions for remediation.  The coverage analyzer sub agent will then pass the summary and recommendations to the coverage test writer sub agent to remediate.

When the coverage test writer sub agent is finished, the coverage analyzer sub agent will execute the commands to run all checks again.  If there are still failures, we are to repeat the cycle.

The checks the coverage test writer sub agent should run depends on the type of project:
   - Go projects:
     * `just test` - Fix any unit testing
     * `just format` - Fix any formatting issues
     * `just lint` - Fix all linting errors
     * `just test` - Ensure all tests pass
     * `just vulncheck` - Ensure there are no known vulnerabilities
   - Rust projects:
     * `just test` - Fix any unit testing
     * `just format` - Fix any formatting issues
     * `just lint` - Fix all linting errors
     * `just test` - Ensure all tests pass
   - JavaScript/TypeScript projects:
     * `npm run test` - Fix any unit testing
     * `npm run format` - Fix any formatting issues
     * `npm run lint` - Fix all linting errors
     * `npm run type-check` - Fix all type errors
     * `npm run build` - Ensure build succeeds
   - Nix projects:
     * `just format` - Fix any formatting issues
     * `just lint` - Fix all linting errors
     * `deadnix` - Fix all dead code errors

If any of these fail, have the coverage analyzer explain the issues to the coverage-test-writer to remediate.  Please loop between the coverage-test-writer and the coverage analyzer until all checks are successful.

IMPORTANT: Be especially mindful of any tests that break that were not a part of the code that was written.  We need to handle any regression errors with care.

Afterwards, have the code-reviewer sub agent review the code that the coverage-test-writer wrote.  If they have concerns with the quality of the code, send it back to the coverage-test-writer where the entire loop begins again with the coverage-test-writer and the coverage analyzer.

Once the code-reviewer is satisfied with the code, we are considered finished.


