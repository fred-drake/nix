Please have the code architect sub agent use the gitea-code-architect mcp to read their assessment to issue 8.  Then, have them send the instructions for phase 1 to  the engineer to accomplish.

Once the engineer is done with the work, including all unit test coverage, have the coverage analyzer sub agent ensure that everything works with the following checks:

    * `npm run test` - Fix any unit testing
    * `npm run format` - Fix any formatting issues
    * `npm run lint` - Fix all linting errors
    * `npm run type-check` - Fix all type errors
    * `npm run build` - Ensure build succeeds

If any of these fail, have the coverage analyzer explain the issues to the engineer to remediate.  Please loop between the engineer and the coverage analyzer until all checks are successful.

IMPORTANT: Be especially mindful of any tests that break that were not a part of the code that was written.  We need to handle any regression errors with care.

Afterwards, have the code-reviewer sub agent review the code that the engineer wrote.  If they have concerns with the quality of the code, send it back to the engineer where the entire loop begins again with the engineer and the coverage analyzer.

Once the code-reviewer is satisfied with the code, we are considered finished.

---

Please have the code architect sub agent use the gitea-code-architect mcp to read their assessment to issue 8.  Then, have them send the instructions for phase 1 to  the engineer to accomplish.

Once the engineer is done with the work, including all unit test coverage, have the coverage analyzer sub agent ensure that everything works with the following checks:

    * `npm run test` - Fix any unit testing
    * `npm run format` - Fix any formatting issues
    * `npm run lint` - Fix all linting errors
    * `npm run type-check` - Fix all type errors
    * `npm run build` - Ensure build succeeds

If any of these fail, have the coverage analyzer explain the issues to the engineer to remediate.  Please loop between the engineer and the coverage analyzer until all checks are successful.

IMPORTANT: Be especially mindful of any tests that break that were not a part of the code that was written.  We need to handle any regression errors with care.

Afterwards, have the code-reviewer sub agent review the code that the engineer wrote.  If they have concerns with the quality of the code, send it back to the engineer where the entire loop begins again with the engineer and the coverage analyzer.

Once the code-reviewer is satisfied with the code, we are considered finished.

