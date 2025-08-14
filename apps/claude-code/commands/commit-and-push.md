# Automated Commit and Push with Quality Loop
## OBJECTIVE
Validate, commit, and push code changes ONLY after ALL quality checks pass through a continuous validation loop.
## Phase 1: Pre-Commit Validation Loop
### VALIDATION LOOP START
1. **Identify Project Type** by checking for:
   - Go: `go.mod`
   - Rust: `Cargo.toml`
   - JavaScript/TypeScript: `package.json`
   - Playwright: `package.json` with `@playwright/test` dependency
   - Nix: `flake.nix` or `default.nix`
2. **Run ALL Quality Checks** for the identified project type:
   **Go Projects - Run in this order:**
   ```bash
   just format
   just lint
   just test
   just vulncheck
   ```
   **Rust Projects - Run in this order:**
   ```bash
   just format
   just lint
   just test
   ```
   **JavaScript/TypeScript Projects - Run in this order:**
   ```bash
   npm run format
   npm run lint
   npm run type-check
   npm run test
   npm run build
   ```
   **Playwright Projects - Run in this order:**
   ```bash
   npm run format
   npm run lint
   npm run type-check
   npm run test
   npm run build
   npm run podman:test
   ```
   **Nix Projects - Run in this order:**
   ```bash
   just format
   just lint
   deadnix
   ```
3. **Capture Check Results:**
   - Count total checks run
   - Count passed checks
   - Count failed checks
   - Store specific error messages for each failure
4. **VALIDATION DECISION POINT:**
   ```
   IF (any check failed):
       - Print: "Validation Loop Iteration #X: Y checks failed"
       - Fix the identified issues
       - Print: "Fixes applied, re-running ALL checks..."
       - GO TO STEP 2 (restart validation)
   ELSE IF (all checks passed):
       - Print: "All Z checks passed! Proceeding to commit phase..."
       - GO TO PHASE 2
   ```
### IMPORTANT LOOP RULES:
- **ALWAYS** re-run ALL checks after ANY fix, not just the failed ones
- **NEVER** skip checks that previously passed
- **TRACK** iteration count to prevent infinite loops
- **ABORT** after 10 iterations and request human intervention
## Phase 2: Intelligent Staging
**ONLY REACHED AFTER ALL CHECKS PASS**
1. **Analyze Changed Files:**
   ```bash
   git status --porcelain
   ```
2. **Categorize Files:**
   - **Auto-stage**: Source code, tests, documentation, config files
   - **Review Required**:
     * Generated files (build artifacts, compiled output)
     * Credential files (.env, secrets, keys)
     * Large files (>1MB)
     * IDE-specific files (.idea/, .vscode/)
     * Package lock files (ask if intentional)
3. **Staging Decision Loop:**
   ```
   FOR each file in changed_files:
       IF (file in review_required_category):
           ASK: "Should I stage {file}? (y/n)"
           IF yes: git add {file}
       ELSE:
           git add {file}
   ```
4. **Logical Commit Grouping:**
   - Group related changes together
   - Separate feature changes from config/dependency updates
   - Ask: "Should I create multiple commits for these changes?"
## Phase 3: Commit Creation
1. **Generate Semantic Commit Message:**
   ```
   Format: type(scope): description
   Types:
   - feat: New feature
   - fix: Bug fix
   - docs: Documentation only
   - style: Code style (formatting, semicolons, etc)
   - refactor: Code restructuring without behavior change
   - test: Adding or modifying tests
   - chore: Maintenance tasks
   ```
2. **Commit Rules:**
   - Main message ≤ 72 characters
   - Use present tense ("add" not "added")
   - Be specific about WHAT changed and WHY
   - If multiple commits needed, create them sequentially
3. **Pre-Push Verification:**
   ```bash
   git log --oneline -n 5  # Show recent commits
   ```
   **Print: "Commits verified. Proceeding with push..."**
   *(No user confirmation required - automatically proceed)*
## Phase 4: Push Process
1. **Final Safety Check:**
   ```bash
   # One more verification run
   git status
   # Ensure we're on the right branch
   git branch --show-current
   ```
2. **Push with Verification:**
   ```bash
   git push origin <current-branch>
   ```
3. **Post-Push Confirmation:**
   - Verify push succeeded
   - Report remote URL and branch
   - Provide link to PR creation if applicable
## Error Handling
**If Validation Loop Fails 10 Times:**
```
ABORT: Quality checks failed to converge after 10 attempts.
Issues that won't resolve:
- [List specific persistent failures]
Manual intervention required.
```
**If Push Fails:**
```
1. Check for remote changes: git fetch origin
2. If behind, ask: "Remote has changes. Pull and merge? (y/n)"
3. If conflicts exist, abort and request manual resolution
```
## Complete Example Flows
### Example 1: Go Project
```
Starting pre-commit validation...
Validation Loop Iteration #1:
Running 4 checks for Go project...
✓ just format - passed
✗ just lint - failed (3 errors)
✗ just test - failed (2 tests)
✓ just vulncheck - passed
Result: 2/4 checks failed
Applying fixes...
Re-running ALL checks...
Validation Loop Iteration #2:
Running 4 checks for Go project...
✓ just format - passed
✓ just lint - passed
✗ just test - failed (1 test)
✓ just vulncheck - passed
Result: 1/4 checks failed
Applying fixes...
Re-running ALL checks...
Validation Loop Iteration #3:
Running 4 checks for Go project...
✓ just format - passed
✓ just lint - passed
✓ just test - passed
✓ just vulncheck - passed
Result: All 4 checks passed! Proceeding to commit phase...
```
### Example 2: Playwright Project
```
Starting pre-commit validation...
Validation Loop Iteration #1:
Running 6 checks for Playwright project...
✓ npm run format - passed
✓ npm run lint - passed
✓ npm run type-check - passed
✓ npm run test - passed
✓ npm run build - passed
✗ npm run podman:test - failed (2 tests)
Result: 1/6 checks failed
Applying fixes...
Re-running ALL checks...
Validation Loop Iteration #2:
Running 6 checks for Playwright project...
✓ npm run format - passed
✓ npm run lint - passed
✓ npm run type-check - passed
✓ npm run test - passed
✓ npm run build - passed
✓ npm run podman:test - passed
Result: All 6 checks passed! Proceeding to commit phase...
Analyzing changes...
Auto-staging: src/main.ts, tests/e2e/login.spec.ts, playwright.config.ts
Review required: .env.example - Should I stage this file? (y/n)
Creating commit...
Commit message: test(e2e): add login flow validation tests
Commits verified. Proceeding with push...
Pushing to origin/feature-branch...
Push successful!
```
## Key Principles
1. **No Shortcuts**: ALL checks must pass before ANY commit
2. **Full Revalidation**: Always re-run ALL checks after ANY change
3. **Clear Feedback**: Report status at each loop iteration
4. **Smart Staging**: Never blindly add all files
5. **Semantic Commits**: Meaningful, well-formatted messages
6. **Safety First**: Multiple confirmation points before push
7. **E2E Testing**: Playwright tests run in headless mode for automation
