We want to improve our test coverage.  Please add test coverage for the file #$ARGUMENTS.

We need a continuous loop cycle where:

- The coverage-test-writer agent will then be responsible for fixing these tests.  When the coverage-test-writer thinks they are finished with a single test, let the coverage-analyzer sub agent know so they can run tests again.
- If the coverage-analyzer finds no errors with `npm run test`, then they are to run further checks to ensure everything is good before we can consider this finished.  If errors are found in any of these, report them back to the coverage-test-writer agent for them to fix.
    * `npm run format` - Fix any formatting issues
    * `npm run lint` - Fix all linting errors
    * `npm run type-check` - Fix all type errors
    * `npm run build` - Ensure build succeeds

If any of these fail, have the coverage analyzer explain the issues to the coverage-test-writer to remediate.  Please loop between the coverage-test-writer and the coverage analyzer until all checks are successful.

IMPORTANT: Be especially mindful of any tests that break that were not a part of the code that was written.  We need to handle any regression errors with care.

Afterwards, have the code-reviewer sub agent review the code that the coverage-test-writer wrote.  If they have concerns with the quality of the code, send it back to the coverage-test-writer where the entire loop begins again with the coverage-test-writer and the coverage analyzer.

Once the code-reviewer is satisfied with the code, we are considered finished.


