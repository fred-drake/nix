# Overall Go Test Coverage Improvement Loop
## OBJECTIVE
Analyze the `coverage.out` file to identify files with poor test coverage and systematically improve test coverage using a continuous loop between sub-agents until all quality checks pass.
## Phase 1: Coverage Analysis and Prioritization
### Initial Coverage Assessment
1. **Read and Parse coverage.out**
   - Parse the Go coverage report format
   - Calculate coverage percentages for each file
   - Identify files with coverage below 80% (configurable threshold)
   - Create prioritized list based on:
     * Files with 0% coverage (highest priority)
     * Critical business logic files with low coverage
     * Files with coverage < 50%
     * Files with coverage 50-80%

2. **Generate Coverage Improvement Plan**
   ```
   Priority 1 (0% coverage):
   - pkg/auth/validator.go: 0%
   - pkg/core/processor.go: 0%
   
   Priority 2 (<50% coverage):
   - pkg/utils/helpers.go: 32%
   - pkg/handlers/api.go: 45%
   
   Priority 3 (50-80% coverage):
   - pkg/models/user.go: 67%
   - pkg/services/email.go: 72%
   ```

## Phase 2: Project Detection and Setup
### Verify Go Project
Confirm project type by checking for:
- `go.mod` file presence
- `coverage.out` file existence and validity
- Test framework in use (standard testing, testify, etc.)

### Define Check Commands
```
TEST_COMMAND="go test ./... -coverprofile=coverage.out"
COVERAGE_REPORT="go tool cover -func=coverage.out"
CHECK_COMMANDS=(
    "go fmt ./..."
    "go vet ./..."
    "golangci-lint run"
    "go test ./... -coverprofile=coverage.out"
    "go tool cover -func=coverage.out"
)
```

## Phase 3: Iterative Test Writing Loop
### MAIN LOOP START - Process Each Low-Coverage File
For each file in the prioritized list:

1. **Coverage-Test-Writer Ultrathinking Phase**
   Before writing tests for the current file, perform deep analysis:
   
   **Coverage Gap Analysis:**
   - Parse coverage.out for specific uncovered lines
   - Identify uncovered functions and methods
   - Map uncovered branches and conditions
   - Prioritize based on code complexity and risk
   
   **Test Strategy Development:**
   - Analyze code structure and dependencies
   - Identify critical paths needing coverage
   - Plan unit vs integration test balance
   - Consider table-driven tests for Go
   - Design test data and fixtures
   
   **Risk-Based Testing:**
   - Focus on error handling paths
   - Test boundary conditions
   - Cover concurrent code carefully
   - Ensure interface implementations are tested

2. **Test Writing Phase**
   Based on coverage gaps and ultrathinking insights:
   - `coverage-test-writer` creates/improves tests for current file
   - Focus on:
     * Covering all uncovered functions
     * Testing error paths and edge cases
     * Using table-driven tests where appropriate
     * Following Go testing conventions
     * Creating subtests with t.Run()
     * Proper cleanup with t.Cleanup() or defer

3. **Incremental Coverage Validation**
   - Run: `go test ./path/to/package -coverprofile=temp_coverage.out`
   - Calculate new coverage for the file
   - Compare with baseline coverage
   
4. **FILE TEST VALIDATION DECISION POINT:**
   ```
   IF (file coverage < 80% AND attempts < 3):
       - Print: "File: [filename] - Coverage: X% (Target: 80%)"
       - coverage-analyzer: Identify remaining uncovered lines
       - GO TO STEP 1 for this file (continue improving)
   ELSE IF (file coverage >= 80%):
       - Print: "✓ File: [filename] - Coverage achieved: X%"
       - Move to next file in priority list
   ELSE:
       - Print: "⚠ File: [filename] - Max attempts reached at X% coverage"
       - Log for manual review
       - Move to next file
   ```

## Phase 4: Full Project Quality Check
After processing all priority files:

5. **Full Test Suite Validation**
   - `coverage-analyzer` runs complete test suite:
   ```bash
   echo "Running full test suite with coverage..."
   go test ./... -coverprofile=coverage.out -v
   go tool cover -func=coverage.out | tail -n 1
   ```

6. **Quality Check Phase**
   - Run ALL quality checks:
   ```bash
   for command in "${CHECK_COMMANDS[@]}"; do
       echo "Running: $command"
       $command
   done
   ```

7. **PROJECT QUALITY DECISION POINT:**
   ```
   IF (any check fails OR overall coverage < target):
       - Print: "Quality Check Failed"
       - coverage-analyzer: Generate detailed report:
         * Current overall coverage vs target
         * Files still below threshold
         * Specific test failures
         * Linting/formatting issues
       - Prioritize fixes
       - GO TO STEP 1 with updated priority list
   ELSE:
       - Print: "All quality checks passed!"
       - GO TO Phase 5 (Coverage Report)
   ```

## Phase 5: Coverage Report and Review
8. **Generate Coverage Report**
   ```bash
   echo "=== COVERAGE IMPROVEMENT REPORT ==="
   echo "Initial Coverage Analysis:"
   # Show before metrics
   
   echo "Final Coverage Analysis:"
   go tool cover -func=coverage.out
   
   echo "Coverage by Package:"
   go test ./... -coverprofile=coverage.out -covermode=count
   go tool cover -func=coverage.out | grep -E "^[^\t]+\t"
   
   echo "Files Improved:"
   # List files with coverage improvements
   
   echo "Files Requiring Manual Review:"
   # List files still below threshold
   ```

9. **Code Review Phase**
   - `code-reviewer` reviews all new test files:
     * Test quality and assertions
     * Proper use of Go testing idioms
     * Table-driven test structure
     * Mock/stub appropriateness
     * No test interdependencies

10. **REVIEW DECISION POINT:**
    ```
    IF (code-reviewer has concerns):
        - Print: "Code review requested changes"
        - Display review report
        - Send feedback to coverage-test-writer
        - GO TO STEP 1 for affected files
    ELSE:
        - Print: "Code review approved"
        - GO TO STEP 11 (final validation)
    ```

## Phase 6: Final Validation
11. **Final Coverage Check**
    ```bash
    echo "Final validation run..."
    go test ./... -coverprofile=coverage.out -race
    TOTAL_COVERAGE=$(go tool cover -func=coverage.out | tail -n 1 | awk '{print $3}')
    echo "Total Project Coverage: $TOTAL_COVERAGE"
    ```

12. **SUCCESS CRITERIA:**
    ```
    IF (total coverage >= 80% AND all checks pass):
        - Print: "SUCCESS: Coverage target achieved!"
        - Generate final HTML report: go tool cover -html=coverage.out
        - COMPLETE
    ELSE IF (significant improvement achieved):
        - Print: "Partial Success: Coverage improved from X% to Y%"
        - List remaining gaps for future work
        - COMPLETE
    ELSE:
        - Print: "Additional manual intervention needed"
        - Provide specific recommendations
    ```

## Go-Specific Testing Patterns
### Table-Driven Tests
```go
tests := []struct {
    name     string
    input    interface{}
    expected interface{}
    wantErr  bool
}{
    {"valid input", validData, expectedResult, false},
    {"nil input", nil, nil, true},
    {"edge case", edgeData, edgeResult, false},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        // test implementation
    })
}
```

### Coverage Improvement Strategies
1. **Focus on Untested Error Paths**
   - Error returns often have low coverage
   - Mock failures in dependencies
   - Test timeout and context cancellation

2. **Interface Testing**
   - Ensure all interface methods are covered
   - Test with multiple implementations
   - Include nil receiver tests

3. **Concurrent Code**
   - Use -race flag during tests
   - Test with various goroutine counts
   - Cover synchronization edge cases

## Loop Control and Safety
### Coverage Tracking
Maintain metrics for:
- Initial overall coverage percentage
- Current overall coverage percentage
- Per-file coverage improvements
- Number of files processed
- Number of tests added

### Regression Prevention
**CRITICAL**: Monitor for:
1. Existing tests that start failing
2. Coverage decreasing in already-tested files
3. Performance degradation from new tests

### Loop Termination
- After 20 files OR 50 iterations:
  ```
  CHECKPOINT: Significant progress made
  Files improved: X/Y
  Coverage increased: Initial% → Current%
  Continue? [Evaluate based on time/value]
  ```

## Example Execution Flow
```
Parsing coverage.out...
Initial Overall Coverage: 42.3%

Priority 1 - Zero Coverage Files:
- pkg/auth/validator.go: 0%
- pkg/core/processor.go: 0%

Processing: pkg/auth/validator.go
- Writing table-driven tests for ValidateToken()
- Adding error case tests
- Coverage achieved: 86.5% ✓

Processing: pkg/core/processor.go
- Writing tests for Process() method
- Adding concurrent processing tests
- Coverage achieved: 78.2% (close enough) ✓

Priority 2 - Low Coverage Files:
- pkg/utils/helpers.go: 32% → 91.3% ✓
- pkg/handlers/api.go: 45% → 83.7% ✓

Running full quality checks...
✓ go fmt ./...
✓ go vet ./...
✓ golangci-lint run
✓ go test ./... (all passing)

=== FINAL COVERAGE REPORT ===
Overall Coverage: 42.3% → 76.8%
Files Improved: 12
Tests Added: 47
Files Still Below Target: 3 (logged for manual review)

Partial Success: Significant improvement achieved!
```

## Integration with CI/CD
Consider adding coverage gates:
```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: go test ./... -coverprofile=coverage.out
- name: Check coverage threshold
  run: |
    COVERAGE=$(go tool cover -func=coverage.out | tail -n 1 | awk '{print $3}' | sed 's/%//')
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage below 80% threshold"
      exit 1
    fi
```