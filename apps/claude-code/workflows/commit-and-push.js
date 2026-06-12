export const meta = {
  name: 'commit-and-push',
  description: 'Validate, commit, and push changes only after all quality checks pass',
  whenToUse: 'Run the full quality-check loop (detect project type, check, fix, re-check), then stage, create semantic commits, and push to origin',
  phases: [
    { title: 'Validate', detail: 'detect project type and run all quality checks', model: 'sonnet' },
    { title: 'Fix', detail: 'fix failed checks, then re-validate (max 10 iterations)', model: 'sonnet' },
    { title: 'Commit', detail: 'stage safe files and create semantic commits', model: 'sonnet' },
    { title: 'Push', detail: 'push to origin and verify', model: 'sonnet' },
  ],
}

const CHECK_MATRIX = `
Identify the project type by checking for these marker files, then run that
type's quality checks IN ORDER:

- Go (go.mod):                  just format; just lint; just test; just vulncheck
- Rust (Cargo.toml):            just format; just lint; just test
- JavaScript/TypeScript
  (package.json):               npm run format; npm run lint; npm run type-check; npm run test; npm run build
- Playwright (package.json
  with @playwright/test dep):   npm run format; npm run lint; npm run type-check; npm run test; npm run build; npm run podman:test
- Nix (flake.nix or
  default.nix):                 just format; just lint; deadnix
`

const VALIDATION_SCHEMA = {
  type: 'object',
  required: ['projectType', 'hasChanges', 'allPassed', 'checks'],
  properties: {
    projectType: { type: 'string', description: 'go | rust | javascript | playwright | nix | unknown' },
    hasChanges: { type: 'boolean', description: 'true if git status --porcelain shows anything to commit' },
    allPassed: { type: 'boolean' },
    checks: {
      type: 'array',
      items: {
        type: 'object',
        required: ['command', 'passed'],
        properties: {
          command: { type: 'string' },
          passed: { type: 'boolean' },
          errors: { type: 'string', description: 'specific error output for failures, empty if passed' },
        },
      },
    },
  },
}

const FIX_SCHEMA = {
  type: 'object',
  required: ['fixesApplied'],
  properties: {
    fixesApplied: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string' },
  },
}

const COMMIT_SCHEMA = {
  type: 'object',
  required: ['commits', 'staged', 'skipped'],
  properties: {
    commits: { type: 'array', items: { type: 'string' }, description: 'commit messages created, in order' },
    staged: { type: 'array', items: { type: 'string' } },
    skipped: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'reason'],
        properties: { file: { type: 'string' }, reason: { type: 'string' } },
      },
    },
  },
}

const PUSH_SCHEMA = {
  type: 'object',
  required: ['pushed', 'branch'],
  properties: {
    pushed: { type: 'boolean' },
    branch: { type: 'string' },
    remote: { type: 'string', description: 'remote URL pushed to' },
    detail: { type: 'string', description: 'failure reason or PR-creation link if applicable' },
  },
}

// ── Phase 1: validation loop ────────────────────────────────────────────────
phase('Validate')
const MAX_ITERATIONS = 10
let validation = null

for (let i = 1; i <= MAX_ITERATIONS; i++) {
  log(`Validation loop iteration #${i}`)
  validation = await agent(
    `You are running pre-commit validation in the current repository. Do NOT fix
anything — only run checks and report results.
${CHECK_MATRIX}
Also run "git status --porcelain" and report whether there are any changes to
commit (hasChanges). Run ALL checks for the project type even if an early one
fails, and capture the specific error output for each failure. If a check's
underlying script/recipe does not exist (e.g. no such just recipe or npm
script), treat it as passed and note that in errors.`,
    { label: `validate#${i}`, phase: 'Validate', schema: VALIDATION_SCHEMA, model: 'sonnet' }
  )
  if (!validation) throw new Error(`validation agent #${i} returned no result`)
  if (!validation.hasChanges) break

  const failed = validation.checks.filter(c => !c.passed)
  if (failed.length === 0) {
    log(`All ${validation.checks.length} checks passed`)
    break
  }

  log(`${failed.length}/${validation.checks.length} checks failed — applying fixes`)
  await agent(
    `Pre-commit quality checks failed in this ${validation.projectType} repository.
Fix the root causes of these failures (do not suppress, skip, or add fallbacks):

${failed.map(c => `### ${c.command}\n${c.errors || '(no error detail captured)'}`).join('\n\n')}

You may re-run individual commands to confirm your fixes, but the full check
suite will be re-run separately afterward. Report each fix you applied.`,
    { label: `fix#${i}`, phase: 'Fix', schema: FIX_SCHEMA, model: 'sonnet' }
  )
}

if (!validation.hasChanges) {
  return { status: 'nothing-to-commit', projectType: validation.projectType }
}
if (!validation.checks.every(c => c.passed)) {
  return {
    status: 'aborted',
    reason: `Quality checks failed to converge after ${MAX_ITERATIONS} iterations. Manual intervention required.`,
    persistentFailures: validation.checks.filter(c => !c.passed),
  }
}

// ── Phase 2+3: staging and semantic commits ─────────────────────────────────
phase('Commit')
const commit = await agent(
  `All quality checks passed. Stage and commit the current changes.

Staging rules — run "git status --porcelain" and categorize every file:
- Auto-stage: source code, tests, documentation, config files.
- DO NOT stage (leave unstaged and report under "skipped" with a reason):
  generated files / build artifacts, credential files (.env, secrets, keys),
  files larger than 1MB, IDE-specific files (.idea/, .vscode/), and package
  lock files whose change looks unintentional. Never "git add -A" blindly.

Commit rules:
- Semantic format "type(scope): description" with type one of feat, fix, docs,
  style, refactor, test, chore.
- Subject line <= 72 characters, present tense, specific about WHAT and WHY.
- Group related changes logically: if the staged changes contain clearly
  separate concerns (e.g. a feature vs. a dependency bump), create multiple
  commits sequentially rather than one mixed commit.

After committing, run "git log --oneline -n 5" to verify. Report the commit
messages created, the files staged, and the files skipped with reasons.`,
  { label: 'stage-and-commit', phase: 'Commit', schema: COMMIT_SCHEMA, model: 'sonnet' }
)
if (!commit) throw new Error('commit agent returned no result')
if (commit.commits.length === 0) {
  return { status: 'aborted', reason: 'No commits were created', skipped: commit.skipped }
}
log(`Created ${commit.commits.length} commit(s)`)

// ── Phase 4: push ───────────────────────────────────────────────────────────
phase('Push')
const push = await agent(
  `Push the commits that were just created on the current branch.

1. Safety check: run "git status" and "git branch --show-current".
2. Run "git fetch origin". If the local branch is behind its upstream, do NOT
   pull, merge, or rebase — report pushed=false with the divergence details so
   a human can resolve it.
3. Otherwise run "git push origin <current-branch>" and verify it succeeded.
4. Report the branch, remote URL, and a PR-creation link if the push output
   provides one.`,
  { label: 'push', phase: 'Push', schema: PUSH_SCHEMA, model: 'sonnet' }
)
if (!push) throw new Error('push agent returned no result')

return {
  status: push.pushed ? 'pushed' : 'push-failed',
  projectType: validation.projectType,
  checksRun: validation.checks.map(c => c.command),
  commits: commit.commits,
  skippedFiles: commit.skipped,
  branch: push.branch,
  remote: push.remote,
  detail: push.detail,
}
