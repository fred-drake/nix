# SonarQube Issue Resolution Loop

## OBJECTIVE
Systematically identify and fix all SonarQube issues using existing sub-agents through a continuous validation loop until the project passes all quality gates.

## Initial Setup

### Required Tools and Sub-Agents
- `code-architect` sub-agent: Analyzes SonarQube issues and creates fix strategies
- `engineer` sub-agent: Implements the fixes
- `coverage-analyzer` sub-agent: Runs validation checks
- `code-reviewer` sub-agent: Reviews code quality
- SonarQube MCP server: For accessing SonarQube data

### Project Type Detection
Automatically detect the project type by checking for:
- **Go**: `go.mod`
- **Rust**: `Cargo.toml`
- **JavaScript/TypeScript**: `package.json`
- **Java**: `pom.xml` or `build.gradle`
- **Python**: `pyproject.toml`

### Define Quality Checks by Project Type
```bash
case $PROJECT_TYPE in
  "go")
    QUALITY_CHECKS=(
      "just format"
      "just lint"
      "just test"
      "just vulncheck"
    )
    ;;
  "rust")
    QUALITY_CHECKS=(
      "just format"
      "just lint"
      "just test"
    )
    ;;
  "javascript"|"typescript")
    QUALITY_CHECKS=(
      "npm run format"
      "npm run lint"
      "npm run type-check"
      "npm run test"
      "npm run build"
    )
    ;;
  "java")
    QUALITY_CHECKS=(
      "mvn clean compile"
      "mvn test"
      "mvn verify"
    )
    ;;
  "python")
    QUALITY_CHECKS=(
      "black --check ."
      "flake8"
      "pytest"
    )
    ;;
esac
```

## Phase 1: SonarQube Analysis

1. **Project Discovery**
   - `code-architect` uses SonarQube MCP to find the associated project
   - Verify project exists and has recent analysis
   - Record current quality gate status and metrics

2. **Issue Retrieval and Analysis**
   - `code-architect` fetches all open issues via SonarQube MCP
   - Performs ultrathinking on the issues:
     * Categorize by severity: BLOCKER → CRITICAL → MAJOR → MINOR → INFO
     * Group by type: BUG → VULNERABILITY → CODE_SMELL
     * Identify issue patterns and root causes
     * Assess fix complexity and risk
     * Create prioritized fix order

3. **Fix Strategy Development**
   - `code-architect` creates comprehensive fix plan:
     * Batch related issues for efficient fixing
     * Identify architectural changes needed
     * Document fix approaches for each issue type
     * Flag high-risk fixes requiring extra care

## Phase 2: Implementation and Validation Loop

### MAIN REMEDIATION LOOP START

4. **Code Architect Issue Analysis**
   For the next priority issue/batch:
   - `code-architect` provides detailed analysis to `engineer`:
     ```
     Issue Details:
     - Severity: [BLOCKER/CRITICAL/MAJOR/MINOR]
     - Type: [BUG/VULNERABILITY/CODE_SMELL]
     - Location: [file:line]
     - Rule: [SonarQube rule explanation]
     - Root Cause: [Why this is problematic]

     Fix Strategy:
     - Recommended approach: [Specific fix instructions]
     - Alternative approaches: [If applicable]
     - Testing considerations: [What to verify]
     - Regression risks: [What might break]
     ```

5. **Engineer Implementation Phase**
   `engineer` performs ultrathinking before implementing:

   **Implementation Analysis:**
   - Review code-architect's recommendations
   - Understand the surrounding code context
   - Identify potential side effects
   - Plan for maintaining code style consistency

   **Fix Implementation:**
   - Apply the recommended fix
   - Ensure fix addresses root cause, not symptoms
   - Add comments if fix logic is complex
   - Consider adding preventive measures

6. **Coverage Analyzer Validation**
   `coverage-analyzer` runs ALL quality checks:
   ```bash
   echo "Running validation for $PROJECT_TYPE project..."
   FAILED_CHECKS=0
   for check in "${QUALITY_CHECKS[@]}"; do
       echo "Executing: $check"
       if ! $check; then
           ((FAILED_CHECKS++))
           echo "❌ Failed: $check"
       else
           echo "✅ Passed: $check"
       fi
   done
   ```

7. **VALIDATION DECISION POINT:**
   ```
   IF (FAILED_CHECKS > 0):
       - Print: "Remediation Loop Iteration #X: Validation failed"
       - coverage-analyzer: Create detailed failure report
       - Identify if failure is due to:
         * The fix itself
         * Regression in other areas
         * Pre-existing test failures
       - Send report to engineer
       - GO TO STEP 5 (retry implementation)
   ELSE:
       - Print: "All quality checks passed!"
       - GO TO STEP 8
   ```

### Regression Handling Protocol
**CRITICAL**: If any existing tests fail:
1. Mark as **HIGH PRIORITY REGRESSION**
2. `coverage-analyzer` provides:
   - Which tests broke
   - Likely connection to the fix
   - Suggested resolution
3. `engineer` MUST fix regression before proceeding

## Phase 3: Code Review Loop

8. **Code Review Phase**
   `code-reviewer` evaluates the fix for:
   - Correctness: Does it actually fix the issue?
   - Quality: Is the code clean and maintainable?
   - Completeness: Are all aspects addressed?
   - Security: No new vulnerabilities introduced?
   - Performance: No significant degradation?
   - Style: Consistent with codebase conventions?

9. **REVIEW DECISION POINT:**
   ```
   IF (code-reviewer has concerns):
       - Print: "Code Review - Changes requested"
       - Provide specific feedback to engineer
       - GO TO STEP 5 (revise implementation)
   ELSE:
       - Print: "Code review approved!"
       - GO TO STEP 10
   ```

## Phase 4: Progress Verification

10. **SonarQube Re-analysis**
    - Trigger new SonarQube analysis
    - Wait for analysis completion
    - `code-architect` fetches updated issue list

11. **PROGRESS DECISION POINT:**
    ```
    IF (more issues exist):
        - Print: "Progress: X issues fixed, Y remaining"
        - Update priority list
        - GO TO STEP 4 (next issue)
    ELSE IF (quality gate still failing):
        - Identify non-issue gate conditions (e.g., coverage)
        - GO TO STEP 4 to address
    ELSE:
        - Print: "SUCCESS: All issues resolved!"
        - GO TO PHASE 5
    ```

## Phase 5: Final Validation

12. **Final Quality Check**
    `coverage-analyzer` runs complete validation one more time:
    ```bash
    echo "Final validation run..."
    for check in "${QUALITY_CHECKS[@]}"; do
        echo "Final check: $check"
        $check || exit 1
    done
    ```

13. **Generate Summary Report**
    ```
    === SonarQube Remediation Summary ===
    Initial State:
    - Quality Gate: FAILED
    - Bugs: X
    - Vulnerabilities: Y
    - Code Smells: Z
    - Coverage: A%

    Final State:
    - Quality Gate: PASSED
    - Bugs: 0
    - Vulnerabilities: 0
    - Code Smells: Reduced by N%
    - Coverage: B%

    Total Iterations: M
    Time Elapsed: T minutes
    ```

## Loop Control and Safety

### Iteration Tracking
```
Track for each iteration:
- Issue being fixed
- Fix attempts for this issue
- Test failures encountered
- Review rounds needed
```

### Complex Issue Protocol
When an issue requires architectural changes:
1. `code-architect` documents the required changes
2. Create separate task for architectural work
3. Skip issue if it blocks progress
4. Continue with other fixable issues

### Maximum Attempts
- Per issue: 5 attempts maximum
- If issue fails 5 times:
  * Document the issue and attempts
  * Add to "manual intervention needed" list
  * Continue with next issue
- Overall loop limit: 100 iterations

## Example Execution Flow

```
Detected project type: TypeScript

Code-Architect: Connecting to SonarQube MCP...
Found project: my-app (Last analysis: 1 hour ago)
Retrieved 35 issues - creating fix strategy...

Remediation Loop Iteration #1:
Code-Architect: Analyzing BLOCKER security vulnerability in auth.ts:45
Engineer: Implementing fix - replacing hardcoded secret
Coverage-Analyzer: Running quality checks...
✅ npm run format
✅ npm run lint
✅ npm run type-check
✅ npm run test
✅ npm run build
All checks passed!
Code-Reviewer: Fix properly addresses security issue - Approved

Remediation Loop Iteration #2:
Code-Architect: Analyzing CRITICAL bug in dataProcessor.ts:127
Engineer: Fixing null reference error
Coverage-Analyzer: Running quality checks...
✅ npm run format
✅ npm run lint
✅ npm run type-check
❌ npm run test (2 failures)
REGRESSION DETECTED: Tests in dataProcessor.test.ts failing

Remediation Loop Iteration #3:
Engineer: Adjusting fix to handle edge case
Coverage-Analyzer: All checks passed!
Code-Reviewer: Good defensive coding - Approved

[... continues until all issues fixed ...]

Final validation: All checks passed!
SUCCESS: SonarQube quality gate now PASSING
```

## Documentation Requirements

Each sub-agent documents their work:

**Code-Architect**: Issue analysis and fix strategy
**Engineer**: What was changed and why
**Coverage-Analyzer**: Test results and regressions
**Code-Reviewer**: Quality assessment and suggestions

Combined into fix log:
```markdown
### Fixed Issue #X
- **Issue**: [SonarQube rule and description]
- **Location**: [file:line]
- **Severity/Type**: [CRITICAL/BUG]
- **Fix Applied**: [What was changed]
- **Validation**: [Tests passed]
- **Review Notes**: [Any important observations]
```
