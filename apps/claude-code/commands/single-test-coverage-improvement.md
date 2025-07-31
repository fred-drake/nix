# Test Coverage Improvement Loop
## OBJECTIVE
Add test coverage for the file `#$ARGUMENTS` using a continuous loop between sub-agents until all quality checks pass.
## Phase 1: Project Detection and Setup
### Auto-Detect Project Type
Check for these files to determine the project type:
- **Go**: Look for `go.mod` or `*.go` files
- **TypeScript/JavaScript**: Look for `package.json` and/or `tsconfig.json`
- **Rust**: Look for `Cargo.toml` (future expansion)
- **Python**: Look for `pyproject.toml` or `requirements.txt` (future expansion)
### Define Check Commands Based on Project Type
**For Go Projects:**
```
TEST_COMMAND="just test"
CHECK_COMMANDS=(
    "just format"
    "just lint"
    "just test"
    "just vulncheck"
)
```
**For TypeScript/JavaScript Projects:**
```
TEST_COMMAND="npm run test"
CHECK_COMMANDS=(
    "npm run format"
    "npm run lint"
    "npm run type-check"
    "npm run test"
    "npm run build"
)
```
## Phase 2: Test Writing Loop
### MAIN LOOP START
1. **Coverage-Test-Writer Ultrathinking Phase**
   Before writing tests, perform deep analysis:
   **Test Strategy Development:**
   - Analyze code structure and identify critical paths
   - Map out all possible execution branches
   - Identify boundary conditions and edge cases
   - Consider error scenarios and exception handling
   - Plan integration vs unit test balance
   **Risk-Based Testing:**
   - Identify high-risk areas needing more coverage
   - Consider business impact of potential failures
   - Evaluate areas prone to regression
   - Assess performance-critical sections
   **Test Design Patterns:**
   - Select appropriate testing patterns (AAA, Given-When-Then)
   - Plan test data management strategy
   - Design mock/stub/spy usage
   - Consider parameterized testing opportunities
   - Plan for test maintainability
2. **Test Writing Phase**
   Based on ultrathinking insights:
   - `coverage-test-writer` creates/improves tests for `#$ARGUMENTS`
   - Focus on:
     * Edge cases and error conditions
     * Happy path scenarios
     * Integration with other components
     * Achieving high code coverage
     * Writing self-documenting test names
     * Implementing identified test patterns
     * Creating maintainable test structures
2. **Initial Test Validation**
   - When `coverage-test-writer` completes a test, notify `coverage-analyzer`
   - `coverage-analyzer` runs: `$TEST_COMMAND`
3. **TEST VALIDATION DECISION POINT:**
   ```
   IF (test command fails):
       - Print: "Test Loop Iteration #X: Tests failing"
       - coverage-analyzer: Explain specific failures to coverage-test-writer
       - GO TO STEP 1 (continue test writing)
   ELSE:
       - Print: "Tests passing, running full quality checks..."
       - GO TO STEP 4
   ```
4. **Full Quality Check Phase**
   - `coverage-analyzer` runs ALL checks for the project type:
   ```bash
   for command in "${CHECK_COMMANDS[@]}"; do
       echo "Running: $command"
       $command
   done
   ```
5. **QUALITY CHECK DECISION POINT:**
   ```
   IF (any check fails):
       - Print: "Quality Check Failed - Iteration #X"
       - coverage-analyzer: Create detailed report including:
         * Which checks failed
         * Specific error messages
         * Files and line numbers affected
         * PRIORITY: Flag any regression errors in existing tests
       - Send report to coverage-test-writer
       - GO TO STEP 1 (restart loop)
   ELSE:
       - Print: "All quality checks passed!"
       - GO TO PHASE 3 (Code Review)
   ```
## Phase 3: Code Review Loop
6. **Code Review Phase**
   - `code-reviewer` sub-agent reviews the test code for:
     * Test quality and completeness
     * Proper assertions and error handling
     * Following testing best practices
     * No unnecessary complexity
     * Appropriate test naming and organization
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
       - GO TO STEP 1 (restart main loop)
   ELSE:
       - Print: "Code review approved"
       - Print: "=== CODE REVIEW REPORT ==="
       - Display the full code-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - GO TO STEP 8 (final validation)
   ```
## Phase 4: Final Validation
8. **Final Check Run**
   - `coverage-analyzer` runs ALL checks one final time:
   ```bash
   echo "Final validation run..."
   for command in "${CHECK_COMMANDS[@]}"; do
       echo "Running: $command"
       $command
   done
   ```
9. **FINAL DECISION POINT:**
   ```
   IF (any check fails):
       - Print: "Final validation failed - restarting loop"
       - GO TO STEP 1
   ELSE:
       - Print: "SUCCESS: All checks passed!"
       - Print test coverage report
       - COMPLETE
   ```
## Loop Control and Safety
### Iteration Tracking
- Maintain counters for:
  * Total loop iterations
  * Test writing attempts
  * Quality check passes/failures
  * Code review rounds
### Regression Prevention
**CRITICAL**: When ANY test fails that wasn't modified:
1. Mark as HIGH PRIORITY regression
2. `coverage-analyzer` must provide:
   - Which existing test broke
   - What change likely caused it
   - Suggested fix that preserves new functionality
3. `coverage-test-writer` MUST fix regressions before proceeding
### Loop Termination
- After 15 iterations without convergence:
  ```
  ABORT: Unable to achieve passing tests after 15 iterations
  Persistent issues:
  - [List unresolved problems]
  Manual intervention required.
  ```
## Example Execution Flow
```
Detected project type: TypeScript
Test Loop Iteration #1:
- coverage-test-writer: Writing tests for utils/validator.ts
- coverage-analyzer: Running npm run test
- Result: 2 tests failing
Test Loop Iteration #2:
- coverage-test-writer: Fixed test assertions
- coverage-analyzer: Tests pass! Running full checks...
- Running: npm run format ✓
- Running: npm run lint ✗ (3 errors)
- Result: Linting errors found
Test Loop Iteration #3:
- coverage-test-writer: Fixed linting issues
- coverage-analyzer: Running full checks...
- All checks passed!
- code-reviewer: Suggests better test descriptions
=== CODE REVIEW REPORT ===
Test Review for utils/validator.ts:
- Test descriptions could be more descriptive
- Consider using 'should' format for clarity
- Example: Change "validates email" to "should reject invalid email formats"
- All assertions look correct
- Good edge case coverage
=== END OF REPORT ===
Test Loop Iteration #4:
- coverage-test-writer: Improved test descriptions
- coverage-analyzer: All checks passed!
- code-reviewer: Approved
=== CODE REVIEW REPORT ===
Test Review for utils/validator.ts:
- All previous concerns addressed
- Test descriptions are now clear and follow best practices
- Excellent coverage of edge cases
- No further changes needed
=== END OF REPORT ===
- Final validation: All checks passed!
SUCCESS: Test coverage added for utils/validator.ts
Coverage increased from 45% to 92%
```
## Language-Specific Considerations
### Go-Specific
- Use table-driven tests where appropriate
- Include benchmark tests for performance-critical code
- Ensure proper cleanup with `defer` statements
### TypeScript-Specific
- Include type assertions in tests
- Mock external dependencies appropriately
- Test both CommonJS and ESM exports if applicable
### Future Language Support
This structure easily extends to other languages by adding:
1. Detection logic in Phase 1
2. Appropriate check commands
3. Language-specific best practices
