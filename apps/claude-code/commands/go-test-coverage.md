We want to improve our test coverage.  Please add test coverage for the file #$ARGUMENTS.

We need a continuous loop cycle where:

- The coverage-test-writer sub agent will then be responsible for fixing these tests.  When the coverage-test-writer thinks they are finished with a single test, let the coverage-analyzer sub agent know so they can run tests again.
- If the coverage-analyzer finds no errors with `just test`, then they are to run further checks to ensure everything is good before we can consider this finished.  If errors are found in any of these, report them back to the coverage-test-writer agent for them to fix.
     * `just format` - Fix any formatting issues
     * `just lint` - Fix all linting errors
     * `just test` - Ensure all tests pass
      `just vulncheck` - Ensure there are no known vulnerabilities

If any of these fail, have the coverage analyzer explain the issues to the coverage-test-writer to remediate.  Please loop between the coverage-test-writer and the coverage analyzer until all checks are successful.

IMPORTANT: Be especially mindful of any tests that break that were not a part of the code that was written.  We need to handle any regression errors with care.

Afterwards, have the code-reviewer sub agent review the code that the coverage-test-writer wrote.  If they have concerns with the quality of the code, send it back to the coverage-test-writer where the entire loop begins again with the coverage-test-writer and the coverage analyzer.

Once the code-reviewer is satisfied with the code, we are considered finished.

