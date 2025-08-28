# CLAUDE.md - Global Instructions for Claude Code
  # This file contains persistent instructions that override default behaviors
  # Documentation: https://docs.anthropic.com/en/docs/claude-code/memory

  ## Core Coding Principles
  1. **No artifacts** - Direct code only
  2. **Less is more** - Rewrite existing components vs adding new
  3. **No fallbacks** - They hide real failures
  4. **Full code output** - Never say "[X] remains unchanged"
  5. **Clean codebase** - Flag obsolete files for removal
  6. **Think first** - Clear thinking prevents bugs

  ## Documentation Structure
  ### Documentation Files & Purpose
  Create `./docs/` folder and maintain these files throughout development:
  - `ROADMAP.md` - Overview, features, architecture, future plans
  - `API_REFERENCE.md` - All endpoints, request/response schemas, examples
  - `DATA_FLOW.md` - System architecture, data patterns, component interactions
  - `SCHEMAS.md` - Database schemas, data models, validation rules
  - `BUG_REFERENCE.md` - Known issues, root causes, solutions, workarounds
  - `VERSION_LOG.md` - Release history, version numbers, change summaries
  - `memory-archive/` - Historical CLAUDE.md content (auto-created by /prune)

  ### Documentation Standards
  **Format Requirements**:
  - Use clear hierarchical headers (##, ###, ####)
  - Include "Last Updated" date and version at top
  - Keep line length ≤ 100 chars for readability
  - Use code blocks with language hints
  - Include practical examples, not just theory

  **Content Guidelines**:
  - Write for future developers (including yourself in 6 months)
  - Focus on "why" not just "what"
  - Link between related docs (use relative paths)
  - Keep each doc focused on its purpose
  - Update version numbers when content changes significantly

  ### Auto-Documentation Triggers
  **ALWAYS document when**:
  - Fixing bugs → Update `./docs/BUG_REFERENCE.md` with:
    - Bug description, root cause, solution, prevention strategy
  - Adding features → Update `./docs/ROADMAP.md` with:
    - Feature description, architecture changes, API additions
  - Changing APIs → Update `./docs/API_REFERENCE.md` with:
    - New/modified endpoints, breaking changes flagged, migration notes
  - Architecture changes → Update `./docs/DATA_FLOW.md`
  - Database changes → Update `./docs/SCHEMAS.md`
  - Before ANY commit → Check if docs need updates

  ### Documentation Review Checklist
  When running `/changes`, verify:
  - [ ] All modified APIs documented in API_REFERENCE.md
  - [ ] New bugs added to BUG_REFERENCE.md with solutions
  - [ ] ROADMAP.md reflects completed/planned features
  - [ ] VERSION_LOG.md has entry for current session
  - [ ] Cross-references between docs are valid
  - [ ] Examples still work with current code

  ## Proactive Behaviors
  - **Bug fixes**: Always document in BUG_REFERENCE.md
  - **Code changes**: Judge if documentable → Just do it
  - **Project work**: Track with TodoWrite, document at end
  - **Personal conversations**: Offer "Would you like this as a note?"

  Critical Reminders

  - Do exactly what's asked - nothing more, nothing less
  - NEVER create files unless absolutely necessary
  - ALWAYS prefer editing existing files over creating new ones
  - NEVER create documentation unless working on a coding project
  - Use claude code commit to preserve this CLAUDE.md on new machines
  - When coding, keep the project as modular as possible.
  - When asked to look at screenshots without a specific path, check ~/Screenshots/ directory