# Playwright Test Fixing Loop with Sub-Agents

You will coordinate a continuous loop between sub-agents until ALL Playwright tests pass successfully across all browsers. Here's the process:

## Initial Setup
First, verify this is a Playwright project by checking for:
- `playwright.config.ts` or `playwright.config.js`
- `package.json` with `@playwright/test` dependency
- `tests/` or `e2e/` directory with `.spec.ts` or `.spec.js` files

## Main Loop Process

### LOOP START: Test Analysis Phase

1. Have the `playwright-analyzer` sub-agent run tests with the single browser first:
   ```bash
   # Initial test run with Chromium only for faster iteration
   TEST_BROWSER=chromium npm run podman:test:headless
   ```

2. The `playwright-analyzer` should create a comprehensive report that includes:
   - Total number of failing tests
   - Specific error messages for each failure
   - Test file paths and test names that failed
   - Classification of errors:
     - Selector/locator failures (HIGH priority)
     - Timeout errors (MEDIUM priority)
     - Assertion failures (HIGH priority)
     - Network/navigation errors (MEDIUM priority)
     - Page crash/console errors (LOW priority)
   - Screenshots or traces if available
   - Flaky test indicators (tests that sometimes pass/fail)

### Test Fixing Phase

3. Pass the analyzer's report to the `playwright-test-writer` sub-agent with these instructions:
   - Fix ALL issues identified in the report
   - Priority order:
     1. Selector/locator issues (update selectors to be more robust)
     2. Assertion failures (fix expected vs actual mismatches)
     3. Timeout issues (add appropriate waits or increase timeouts)
     4. Network/navigation issues (handle loading states properly)
   - Best practices to follow:
     - Use data-testid attributes when possible
     - Implement proper wait strategies (waitForLoadState, waitForSelector)
     - Add retry logic for flaky operations
     - Use page.locator() instead of page.$()
   - Document what changes were made and why

### Single Browser Verification Phase

4. After `playwright-test-writer` completes, have `playwright-analyzer` run Chromium tests again:
   ```bash
   TEST_BROWSER=chromium npm run podman:test:headless
   ```

5. **CHROMIUM DECISION POINT:**
   - If ANY Chromium test fails: GO TO STEP 2 (continue loop with Chromium)
   - If ALL Chromium tests pass: GO TO STEP 6 (multi-browser testing)

### Multi-Browser Testing Phase

6. Once Chromium passes, have `playwright-analyzer` run ALL browser tests:
   ```bash
   # Run tests across all configured browsers (typically chromium, firefox, webkit)
   npm run podman:test:headless
   ```

7. **MULTI-BROWSER DECISION POINT:**
   - If ANY browser has failures:
     - Create browser-specific fix report
     - Focus on cross-browser compatibility issues
     - GO TO STEP 3 with browser-specific fixes
   - If ALL browsers pass: GO TO STEP 8 (code review)

### Code Review Phase

8. Once all browser tests pass, have the `playwright-reviewer` sub-agent review the changes with focus on:
   - Selector robustness (avoiding brittle selectors)
   - Proper use of Playwright APIs
   - Test reliability and flakiness prevention
   - Appropriate wait strategies
   - Cross-browser compatibility considerations
   - Test maintainability and readability
   - **OUTPUT**: Create a detailed review report

9. **REVIEW DECISION POINT:**
   ```
   IF (playwright-reviewer has concerns):
       - Print: "Code review requested changes"
       - Print: "=== PLAYWRIGHT REVIEW REPORT ==="
       - Display the full playwright-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - Wait for user acknowledgment (optional)
       - Send feedback to playwright-test-writer
       - GO TO STEP 1 (restart loop with Chromium)
   ELSE:
       - Print: "Code review approved"
       - Print: "=== PLAYWRIGHT REVIEW REPORT ==="
       - Display the full playwright-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - GO TO STEP 10 (final verification)
   ```

### Final Verification

10. Have `playwright-analyzer` run the FULL test suite one final time across all browsers:
    ```bash
    npm run podman:test:headless
    ```

11. **FINAL DECISION POINT:**
    - If ANY test fails in ANY browser: GO TO STEP 2 (restart main loop)
    - If ALL tests pass in ALL browsers: COMPLETE - Exit loop

## Loop Control Instructions

**IMPORTANT:** You must implement actual loop control:
- Keep a counter of loop iterations
- Track which browsers are passing/failing
- After each phase, explicitly check the exit conditions
- Use clear statements like:
  - "Chromium: 3 failures, continuing iteration #X"
  - "All browsers passing, proceeding to code review"
  - "Firefox failing on login test, fixing browser-specific issue"

**LOOP TERMINATION:** Only exit when:
1. ALL tests pass in Chromium (0 failures)
2. AND all tests pass in ALL configured browsers (0 failures)
3. AND playwright-reviewer has no concerns
4. AND final verification passes across all browsers

**INFINITE LOOP PREVENTION:** If the loop has run 10 times without success:
- Have `playwright-analyzer` create a detailed failure report including:
  - Consistently failing tests
  - Browser-specific issues
  - Potential environment problems
  - Suggested manual interventions
- Escalate to human for manual intervention

## Example Loop Execution

```
Iteration 1:
- Analyzer: Testing with Chromium
- Found: 5 test failures (3 selector issues, 2 timeout errors)
- Test Writer: Updated selectors, added explicit waits
- Analyzer: Chromium - 2 tests still failing
- Status: CONTINUE LOOP (Chromium not passing)

Iteration 2:
- Analyzer: Found 2 Chromium failures (assertion mismatches)
- Test Writer: Fixed assertions, updated expected values
- Analyzer: Chromium - All tests pass (0 failures)
- Status: PROCEED TO MULTI-BROWSER

Iteration 3:
- Analyzer: Testing all browsers
- Results: Chromium ✓, Firefox ✗ (2 failures), WebKit ✗ (1 failure)
- Test Writer: Added browser-specific handling for Firefox, fixed WebKit viewport issue
- Analyzer: All browsers pass
- Playwright Reviewer: Suggests improving selector strategy
=== PLAYWRIGHT REVIEW REPORT ===
Review Summary:
- All tests passing across browsers
- Consider using data-testid for .login-button selector
- The wait strategy in checkout flow could be more robust
- Add retry mechanism for flaky network test
=== END OF REPORT ===
- Status: CONTINUE LOOP

Iteration 4:
- Test Writer: Implements reviewer suggestions
- Analyzer: All browsers pass
- Playwright Reviewer: Approved
=== PLAYWRIGHT REVIEW REPORT ===
Review Summary:
- Selector strategy now robust with data-testid
- Wait strategies properly implemented
- Retry logic added for network operations
- Cross-browser compatibility verified
- No further changes needed
=== END OF REPORT ===
- Final Check: All browsers pass
- Status: COMPLETE
```

## Browser-Specific Considerations

When fixing cross-browser issues, consider:
- **WebKit/Safari**: Stricter security policies, different viewport handling
- **Firefox**: Different event timing, unique developer tools behavior
- **Chromium**: Generally most permissive, good baseline

Remember: This is a LOOP, not a sequence. Start with Chromium for speed, then expand to all browsers only after Chromium passes completely.
