OBJECTIVE: Improve code coverage by adding strategic unit tests to this codebase.

IMPORTANT: Use the test-coverage-generator sub agent

PROCESS:
1. ANALYZE current code coverage to identify gaps:
   - Review coverage percentages for each function and method
   - Prioritize untested code by: critical business logic > public APIs > complex functions > simple utilities

2. WRITE targeted unit tests for uncovered code:
   - Focus on high-impact areas first (functions with multiple branches, error handling, edge cases)
   - Include both positive and negative test cases
   - Test boundary conditions and edge cases
   - ALWAYS mock external dependencies (databases, APIs, file systems, etc.)

3. RUN tests using the appropriate command:
   - JavaScript/TypeScript: `npm run test`
   - Go/Rust: `just test`

4. ITERATE:
   - Check updated coverage metrics
   - Repeat process for remaining uncovered code until reaching desired coverage threshold

TESTING PRINCIPLES:
- Each test should verify one specific behavior
- Test names should clearly describe what is being tested
- Aim for meaningful coverage, not just percentage metrics