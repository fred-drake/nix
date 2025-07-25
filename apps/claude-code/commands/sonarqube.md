# SonarQube Issue Resolution Prompt for Claude Code

I need help fixing SonarQube issues in my project. Please use the SonarQube MCP to:

## 1. Find the SonarQube project that associates with our codebase
Find our Sonar project

## 1. Scan and list all issues
Within this project, get a complete list of current SonarQube issues, organized by severity (Blocker → Critical → Major → Minor → Info)

## 2. Fix issues by priority
Start with the highest severity issues and work down:
- For each issue, explain what the problem is and why it matters
- Implement the fix directly in the code
- Verify the fix doesn't break existing functionality

## 3. Focus on these issue types first (if present):
- Security vulnerabilities
- Bugs that could cause runtime errors
- Code smells that significantly impact maintainability

## 4. Document your changes
For each fix, briefly note:
- What was changed
- Why it resolves the issue
- Any potential side effects to watch for

Please proceed systematically through the issues, and let me know if any issues require architectural changes or have dependencies that prevent immediate fixing.