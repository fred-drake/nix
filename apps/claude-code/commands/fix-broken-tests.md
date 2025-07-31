# Test Fixing Loop with Sub-Agents
You will coordinate a continuous loop between sub-agents until ALL tests, linting, and formatting checks pass successfully. Here's the process:
## Initial Setup
First, identify the project type by checking for these files:
- Go: `go.mod`
- Rust: `Cargo.toml`
- JavaScript/TypeScript: `package.json`
- Nix: `flake.nix` or `default.nix`
## Main Loop Process
### LOOP START: Test Analysis Phase
1. Have the `coverage-analyzer` sub-agent run ALL applicable checks for the project type:
   **For Go projects:**
   ```
   just test
   just format
   just lint
   just vulncheck
   ```
   **For Rust projects:**
   ```
   just test
   just format
   just lint
   ```
   **For JavaScript/TypeScript projects:**
   ```
   npm run test
   npm run format
   npm run lint
   npm run type-check
   npm run build
   ```
   **For Nix projects:**
   ```
   just format
   just lint
   deadnix
   ```
2. The `coverage-analyzer` should create a comprehensive report that includes:
   - Total number of failing tests/checks
   - Specific error messages for each failure
   - File paths and line numbers where errors occur
   - Classification of errors (test failures, lint errors, format issues, etc.)
   - Priority order for fixing (regression errors should be marked as HIGH priority)
### Test Fixing Phase
3. Pass the analyzer's report to the `coverage-test-writer` sub-agent with these instructions:
   - Fix ALL issues identified in the report
   - Start with HIGH priority regression errors
   - Make minimal changes to avoid introducing new issues
   - Document what changes were made and why
### Verification Phase
4. After `coverage-test-writer` completes, have `coverage-analyzer` run ALL checks again.
5. **CRITICAL DECISION POINT:**
   - If ANY test, lint, format, or build check fails: GO TO STEP 2 (continue loop)
   - If ALL checks pass: GO TO STEP 6 (code review)
### Code Review Phase
6. Once all tests pass, have the `code-reviewer` sub-agent review the changes with focus on:
   - Code quality and maintainability
   - Proper error handling
   - Test coverage adequacy
   - No unnecessary changes or over-engineering
   - Compliance with project conventions
   - **OUTPUT**: Create a detailed review report
7. **REVIEW DECISION POINT:**
   ```
   IF (code-reviewer has concerns):
       - Print: "Code review requested changes"
       - Print: "=== CODE REVIEW REPORT ==="
       - Display the full code-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - Wait for user acknowledgment (optional)
       - Send feedback to coverage-test-writer
       - GO TO STEP 1 (restart loop)
   ELSE:
       - Print: "Code review approved"
       - Print: "=== CODE REVIEW REPORT ==="
       - Display the full code-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - GO TO STEP 8 (final verification)
   ```
### Final Verification
8. Have `coverage-analyzer` run the FULL test suite one final time.
9. **FINAL DECISION POINT:**
   - If ANY check fails: GO TO STEP 2 (restart main loop)
   - If ALL checks pass: COMPLETE - Exit loop
## Loop Control Instructions
**IMPORTANT:** You must implement actual loop control:
- Keep a counter of loop iterations
- After each phase, explicitly check the exit conditions
- Use clear statements like "Tests still failing, continuing loop iteration #X"
- Do not proceed to completion until you see: "All X tests passed, 0 failures"
**LOOP TERMINATION:** Only exit when:
1. ALL automated checks pass (0 failures across all commands)
2. AND code-reviewer has no concerns
3. AND final verification passes
**INFINITE LOOP PREVENTION:** If the loop has run 10 times without success:
- Have `coverage-analyzer` create a detailed failure report
- Escalate to human for manual intervention
- Document which tests consistently fail to converge
## Example Loop Execution
```
Iteration 1:
- Analyzer: Found 5 test failures, 3 lint errors
- Test Writer: Fixed issues
- Analyzer: 2 tests still failing
- Status: CONTINUE LOOP
Iteration 2:
- Analyzer: Found 2 test failures
- Test Writer: Fixed remaining issues
- Analyzer: All tests pass (0 failures)
- Code Reviewer: Suggests refactoring
=== CODE REVIEW REPORT ===
Code Review Summary:
- All tests are passing correctly
- Consider refactoring the error handling in utils.js
- The helper function could be more concise
- Test coverage is adequate but could include edge case for null input
=== END OF REPORT ===
- Status: CONTINUE LOOP
Iteration 3:
- Test Writer: Implements reviewer suggestions
- Analyzer: All tests pass
- Code Reviewer: Approved
=== CODE REVIEW REPORT ===
Code Review Summary:
- All previous concerns have been addressed
- Error handling is now robust
- Helper function is clean and efficient
- Edge cases are properly tested
- No further changes needed
=== END OF REPORT ===
- Final Check: All tests pass
- Status: COMPLETE
```
Remember: This is a LOOP, not a sequence. You must repeatedly cycle through these phases until all conditions are met.
