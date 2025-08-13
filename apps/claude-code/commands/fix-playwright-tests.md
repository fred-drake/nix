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

### Test Fixing Phase with MCP

3. Pass the analyzer's report to the `playwright-test-writer` sub-agent with these instructions:
   
   **IMPORTANT: The playwright-test-writer should use the Playwright MCP for enhanced test fixing:**
   
   **MCP Integration Instructions:**
   - Connect to the Playwright MCP server before making any changes
   - Use MCP to analyze failing test patterns and get fix suggestions
   - Query MCP for:
     - Best selector strategies for failed elements
     - Recommended wait strategies based on error types
     - Cross-browser compatibility fixes
     - Historical fixes for similar issues
   
   **Fix ALL issues identified in the report:**
   - Priority order:
     1. Selector/locator issues (use MCP to find more robust selectors)
     2. Assertion failures (use MCP to verify expected values)
     3. Timeout issues (use MCP to determine optimal wait strategies)
     4. Network/navigation issues (use MCP for loading state recommendations)
   
   **Best practices to follow:**
   - Use data-testid attributes when possible (MCP can suggest these)
   - Implement proper wait strategies (MCP recommends: waitForLoadState, waitForSelector)
   - Add retry logic for flaky operations (MCP identifies flaky patterns)
   - Use page.locator() instead of page.$()
   - Document what changes were made and why
   
   **MCP-Enhanced Fixes:**
   - Let MCP analyze the DOM structure for better selectors
   - Use MCP's timing analysis to set appropriate timeouts
   - Apply MCP's browser-specific recommendations
   - Leverage MCP's test stability patterns

### Single Browser Verification Phase

4. After `playwright-test-writer` completes (using MCP), have `playwright-analyzer` run Chromium tests again:
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
     - GO TO STEP 3 with browser-specific fixes (using MCP)
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

## MCP Usage Guidelines for playwright-test-writer

When the `playwright-test-writer` uses the Playwright MCP, it should:

1. **Connect to MCP:**
   - Establish connection to Playwright MCP server
   - Verify MCP is available and responsive

2. **Analyze Failures with MCP:**
   - Submit failing test details to MCP
   - Request fix recommendations based on error types
   - Get selector suggestions for failed locators
   - Query optimal wait strategies

3. **Apply MCP Recommendations:**
   - Use MCP-suggested selectors that are more robust
   - Implement MCP-recommended wait patterns
   - Apply browser-specific fixes from MCP
   - Follow MCP's retry logic suggestions

4. **Validate Fixes with MCP:**
   - Before finalizing, verify fixes with MCP
   - Check if similar fixes have worked before
   - Ensure cross-browser compatibility

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
- Test Writer: Connecting to Playwright MCP...
- MCP: Analyzing failures and suggesting fixes
- Test Writer: Applied MCP-recommended selectors and wait strategies
- Analyzer: Chromium - 2 tests still failing
- Status: CONTINUE LOOP (Chromium not passing)

Iteration 2:
- Analyzer: Found 2 Chromium failures (assertion mismatches)
- Test Writer: Using MCP to verify expected values
- MCP: Provided correct assertion values based on DOM analysis
- Test Writer: Fixed assertions with MCP-verified values
- Analyzer: Chromium - All tests pass (0 failures)
- Status: PROCEED TO MULTI-BROWSER

Iteration 3:
- Analyzer: Testing all browsers
- Results: Chromium ✓, Firefox ✗ (2 failures), WebKit ✗ (1 failure)
- Test Writer: Connecting to MCP for browser-specific fixes
- MCP: Identified Firefox event timing issue, WebKit viewport problem
- Test Writer: Applied MCP browser-specific recommendations
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
- Test Writer: Using MCP to implement reviewer suggestions
- MCP: Provided data-testid selector patterns and retry templates
- Test Writer: Applied MCP-enhanced improvements
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

When fixing cross-browser issues (playwright-test-writer should use MCP for these):
- **WebKit/Safari**: Stricter security policies, different viewport handling
- **Firefox**: Different event timing, unique developer tools behavior
- **Chromium**: Generally most permissive, good baseline

Remember: This is a LOOP, not a sequence. Start with Chromium for speed, then expand to all browsers only after Chromium passes completely. The Playwright MCP is used specifically during the test fixing phase to provide enhanced fix recommendations and validation.
