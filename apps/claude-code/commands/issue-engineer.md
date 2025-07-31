# Gitea Issue Implementation Loop

## OBJECTIVE
Fetch implementation instructions from a Gitea issue comment and execute them with continuous quality validation until all checks pass.

## Initial Setup

### Parse Arguments
```
COMMENT_INDICES = $1  # First argument: Comma-separated issue comment indices (e.g., "18,50")
PHASE_NUMBER = $2     # Second argument: Phase to implement

# Parse multiple indices
IFS=',' read -ra COMMENT_ARRAY <<< "$COMMENT_INDICES"
echo "Will fetch ${#COMMENT_ARRAY[@]} issue comments: ${COMMENT_ARRAY[@]}"
```

### Project Type Detection
Automatically detect the project type by checking for:
- **Go**: `go.mod` or `*.go` files
- **Rust**: `Cargo.toml`
- **JavaScript/TypeScript**: `package.json` and/or `tsconfig.json`
- **Nix**: `flake.nix` or `default.nix`

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
  "nix")
    QUALITY_CHECKS=(
      "just format"
      "just lint"
      "deadnix"
    )
    ;;
esac
```

## Phase 1: Fetch and Parse Instructions

1. **Fetch Issue Instructions**
   - Have `code-architect` sub-agent use `gitea-code-architect` MCP server
   - Retrieve ALL issue single comments specified in `COMMENT_INDICES`:
   ```bash
   for index in "${COMMENT_ARRAY[@]}"; do
       echo "Fetching issue comment #$index..."
       # Fetch and store comment content
   done
   ```
   - Combine information from all fetched comments
   - Extract implementation instructions for phase `PHASE_NUMBER`

2. **Code Architect Ultrathinking Phase**
   Before creating the implementation plan, `code-architect` performs deep analysis:

   **Technical Deep Dive:**
   - Analyze the architectural implications of the requirements
   - Identify potential design patterns and anti-patterns
   - Consider performance implications and bottlenecks
   - Evaluate security vulnerabilities and mitigation strategies
   - Map out data flow and system interactions

   **Risk and Complexity Assessment:**
   - Identify technical debt that might be introduced
   - Evaluate coupling and cohesion impacts
   - Consider edge cases and failure scenarios
   - Assess backward compatibility concerns

   **Alternative Approaches:**
   - Generate 2-3 different implementation strategies
   - Compare trade-offs between approaches
   - Consider long-term maintainability
   - Evaluate testing complexity for each approach

3. **Prepare Implementation Plan**
   Based on ultrathinking analysis:
   - `code-architect` synthesizes instructions from all fetched comments
   - Resolve any conflicting requirements between comments
   - Create unified instructions for phase `PHASE_NUMBER`
   - Include acceptance criteria from all relevant comments
   - Provide specific technical guidance based on deep analysis
   - Highlight critical implementation considerations
   - Recommend preferred approach with justification

## Phase 2: Implementation and Validation Loop

### MAIN IMPLEMENTATION LOOP START

3. **Engineer Ultrathinking Phase**
   Before implementing, `engineer` performs deep analysis:

   **Implementation Strategy:**
   - Review code-architect's recommendations and requirements
   - Analyze existing codebase for integration points
   - Identify reusable components and patterns
   - Consider performance optimization opportunities
   - Plan error handling and recovery strategies

   **Code Quality Planning:**
   - Design for testability and maintainability
   - Plan appropriate abstractions and interfaces
   - Consider SOLID principles application
   - Identify areas needing documentation
   - Plan for observability (logging, metrics)

   **Risk Mitigation:**
   - Identify potential breaking changes
   - Plan rollback strategies
   - Consider feature flags for gradual rollout
   - Assess impact on existing functionality

4. **Implementation Phase**
   Based on ultrathinking insights:
   - `engineer` implements the instructions from `code-architect`
   - Focus on:
     * Meeting the specific requirements for phase `PHASE_NUMBER`
     * Writing clean, maintainable code
     * Following identified patterns and best practices
     * Adding appropriate tests and documentation
     * Implementing robust error handling
     * Ensuring performance optimization where identified

4. **Quality Validation Phase**
   - After `engineer` completes implementation, `coverage-analyzer` runs ALL quality checks:
   ```bash
   echo "Running quality checks for $PROJECT_TYPE project..."
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

5. **VALIDATION DECISION POINT:**
   ```
   IF (FAILED_CHECKS > 0):
       - Print: "Implementation Loop Iteration #X: $FAILED_CHECKS checks failed"
       - coverage-analyzer: Create detailed failure report:
         * Specific errors and locations
         * Stack traces if applicable
         * PRIORITY FLAG for any regression errors
       - Send report to engineer
       - GO TO STEP 3 (continue implementation loop)
   ELSE:
       - Print: "All quality checks passed! Proceeding to code review..."
       - GO TO PHASE 3
   ```

### Regression Handling Protocol
**CRITICAL**: If any existing tests fail that weren't modified:
1. `coverage-analyzer` immediately flags as **HIGH PRIORITY REGRESSION**
2. Creates regression report with:
   - Which existing tests broke
   - Likely cause analysis
   - Suggested fix approach
3. `engineer` MUST address regressions before any other fixes

## Phase 3: Code Review Loop

6. **Code Review Phase**
   - `code-reviewer` evaluates the implementation against:
     * Original Gitea issue requirements
     * Code quality standards
     * Best practices for the language
     * Performance considerations
     * Security implications
   - **OUTPUT**: Create a detailed review report

7. **REVIEW DECISION POINT:**
   ```
   IF (code-reviewer has concerns):
       - Print: "Code Review Iteration #X: Changes requested"
       - Print: "=== CODE REVIEW REPORT ==="
       - Display the full code-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - Document specific concerns:
         * Code quality issues
         * Missing requirements
         * Potential bugs or edge cases
       - Wait for user acknowledgment (optional)
       - Send feedback to engineer
       - GO TO STEP 3 (restart implementation loop)
   ELSE:
       - Print: "Code review approved!"
       - Print: "=== CODE REVIEW REPORT ==="
       - Display the full code-reviewer report to the user
       - Print: "=== END OF REPORT ==="
       - GO TO PHASE 4
   ```

## Phase 4: Final Validation

8. **Final Quality Check**
   - `coverage-analyzer` runs complete validation suite one more time:
   ```bash
   echo "Final validation for phase $PHASE_NUMBER implementation..."
   ALL_PASSED=true
   for check in "${QUALITY_CHECKS[@]}"; do
       echo "Final check: $check"
       if ! $check; then
           ALL_PASSED=false
           echo "❌ Final validation failed: $check"
           break
       fi
   done
   ```

9. **FINAL DECISION POINT:**
   ```
   IF (!ALL_PASSED):
       - Print: "Final validation failed - restarting from implementation"
       - GO TO STEP 3
   ELSE:
       - Print: "SUCCESS: Phase $PHASE_NUMBER implementation complete!"
       - Log implementation summary
       - COMPLETE
   ```

## Loop Control and Monitoring

### Progress Tracking
Maintain these metrics throughout execution:
- Total loop iterations
- Implementation attempts per phase
- Quality check failures by type
- Code review rounds
- Time spent in each phase

### Loop Safety Limits
```
MAX_ITERATIONS = 20
if (current_iteration > MAX_ITERATIONS):
    ABORT with detailed status:
    - Phase attempted: $PHASE_NUMBER
    - Persistent failures
    - Last error state
    - Recommendation for manual intervention
```

### Status Reporting Format
```
=== Gitea Issue Implementation Status ===
Issue Comments: #$COMMENT_INDICES (${#COMMENT_ARRAY[@]} comments)
Phase: $PHASE_NUMBER
Project Type: $PROJECT_TYPE
Loop Iteration: #X
Status: [Implementation|Validation|Review|Final Check]
----------------------------------------
```

## Example Execution Flow

```
Parsing arguments: COMMENT_INDICES="18,50", PHASE_NUMBER=2
Will fetch 2 issue comments: 18 50
Detected project type: Go

Fetching Gitea issue comment #18...
Fetching Gitea issue comment #50...
Synthesizing requirements from 2 comments...
Extracting phase 2 requirements...

Implementation Loop Iteration #1:
- Engineer implementing phase 2 requirements from comments #18,50
- Running quality checks for Go project...
  ✅ just format
  ❌ just lint (3 errors)
  ❌ just test (2 failures)
  ✅ just vulncheck
Result: 2 checks failed

Implementation Loop Iteration #2:
- Engineer fixing lint and test issues
- Running quality checks...
  ✅ just format
  ✅ just lint
  ❌ just test (1 regression detected!)
  ✅ just vulncheck
HIGH PRIORITY: Regression in existing test detected

Implementation Loop Iteration #3:
- Engineer fixing regression while preserving new functionality
- All quality checks passed!
- Code reviewer examining implementation...

Code Review Iteration #1:
- Reviewer suggests refactoring for clarity
=== CODE REVIEW REPORT ===
Code Review for Phase 2 Implementation:
- Implementation meets all requirements from comments #18 and #50
- Suggest refactoring the processData function for better clarity
- Consider extracting the validation logic into a separate method
- Error handling is adequate but could use more specific error types
- Test coverage is good but missing edge case for empty input
=== END OF REPORT ===
- Engineer implementing suggestions

Implementation Loop Iteration #4:
- All quality checks passed!
- Code review approved!
=== CODE REVIEW REPORT ===
Code Review for Phase 2 Implementation:
- All previous concerns have been addressed
- Code is clean, well-structured, and maintainable
- Error handling is now comprehensive with specific error types
- Test coverage includes all edge cases
- Implementation fully satisfies requirements
- No further changes needed
=== END OF REPORT ===
- Running final validation...
- All checks passed!

SUCCESS: Phase 2 implementation complete!
Time elapsed: 8 minutes
Total iterations: 4
```

## Integration Notes

### Multi-Comment Handling
When multiple comment indices are provided:
1. **Fetch Order**: Retrieve comments in the order specified
2. **Conflict Resolution**: If comments contain conflicting requirements:
   - Later comments take precedence over earlier ones
   - Flag conflicts to engineer for awareness
   - Document resolution decisions
3. **Requirement Synthesis**: Combine all requirements into cohesive plan
4. **Context Preservation**: Maintain reference to source comment for each requirement

### MCP Server Communication
- `code-architect` must establish connection to `gitea-code-architect` MCP server
- Handle authentication and connection errors gracefully
- Cache all fetched comment data to avoid repeated fetches
- Batch fetch multiple comments if MCP server supports it

### Multi-Phase Coordination
- Each phase builds on previous phases
- Maintain phase dependency awareness
- Consider cumulative testing impact

### Error Recovery
- Network failures: Retry with exponential backoff
- MCP server errors: Provide clear diagnostics
- Build failures: Capture full logs for analysis
