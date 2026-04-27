---
name: woodpecker-pipelines
description: Patterns and hard-won gotchas for designing, debugging, and writing Woodpecker CI pipeline files. Use when authoring or editing `.woodpecker.yml` / `.woodpecker/*.yml`, when a pipeline shows `error` status with no step logs, when shell variables in `commands:` blocks are not interpolating as expected, when splitting between single-file and multi-pipeline directory layouts, or when running iOS signing / archive flows on a non-interactive Mac agent. Companion to the `woodpecker-cli` skill (which is the CLI reference) — this one is the workflow-design + debugging reference.
---

# Woodpecker pipelines

## File layout: single-file vs multi-file is exclusive

A repo can have either `.woodpecker.yml` at the root, **or** a `.woodpecker/` directory containing one or more `*.yml` files. The two modes are mutually exclusive at the server level: as soon as `.woodpecker/` exists with any `.yml` files, the single-file `.woodpecker.yml` is ignored even if still present. To migrate from one mode to the other, do it in a single commit (e.g. `git mv .woodpecker.yml .woodpecker/ci.yml`) so there is never a window where one is silently being read.

## Multi-workflow trigger semantics

In multi-file mode, **every workflow whose `when:` matches the trigger runs in parallel**. There is no concept of a "primary" workflow. To make a manual "Run Pipeline" click trigger only one workflow (e.g., a TestFlight submission, not a regular CI run), include `event: manual` in the target workflow's `when:` and **omit** `manual` from every other workflow's `when:`.

Failure mode: leaving `event: [push, pull_request, manual]` on a CI workflow and `event: manual` on a release workflow means a single Run-Pipeline click fires both in parallel — likely shipping accidentally.

```yaml
# .woodpecker/ci.yml — push + PR only
when:
  - event: [push, pull_request]

# .woodpecker/release.yml — manual only
when:
  - event: manual
```

## Variable interpolation in `commands:` is a minefield

Woodpecker pre-processes every `commands:` string through its own templating engine before bash ever sees it. The templater inherits Drone's `${build.*}` / `${commit.*}` etc. namespace and is finicky about syntax. Empirically the failure modes vary by form:

| In your YAML | What Woodpecker does |
| --- | --- |
| `${VAR}` | Substitutes to the matching template var, or to **empty string** if the name is unknown. No error. |
| `$VAR` (bare, no braces) | Sometimes passes through (e.g., `$HOME`, `$2` in `awk '{print $2}'`); sometimes errors with `"unable to parse variable name"` and rejects the entire workflow. The split is not predictable from the YAML alone. |
| `$${VAR}` | Errors with `"missing closing brace"` and rejects the workflow. Despite `$$` being documented as the escape, combining it with `{...}` doesn't pass through cleanly. |

**Worst-case symptom:** in multi-pipeline layouts, a templating rejection in one workflow blocks **every other workflow in the repo** from running for that trigger. So a botched `${VAR}` in a release workflow can stop the regular CI dead, with no obvious connection.

**Rule of thumb when you need to use a value inside `commands:`:**

1. **If the value is static, write it literally.** No interpolation, no surprises.
2. **If the value comes from secrets or repo-level config, use the step's `environment:` map.** Woodpecker resolves it at scheduling time, before the templater runs.
   ```yaml
   environment:
     ASC_KEY_ID:
       from_secret: asc_key_id
     PROFILE_NAME: "Thrifter App Store Distribution"
   ```
   Then bash sees `$ASC_KEY_ID` as a normal env var. No YAML-side `$`.
3. **If the value comes from runtime computation (file contents, tool output), keep it inside `$(...)`** command substitution. The templater does not try to parse inside command substitution. The result lives in a bash-local variable that you reference with bare `$name` inside the same `|` block — and **do not** put that bash variable inside another double-quoted YAML string that the templater will scan.
4. **If you absolutely must interpolate a runtime value into a string Woodpecker scans, write the string to a file and pass the file** (`git commit -F /tmp/msg`, `xcodebuild -exportOptionsPlist /tmp/opts.plist`, etc.).

`woodpecker-cli lint` does **not** catch any of these templating issues — it accepts forms the server later rejects. Treat lint as syntax-only.

## Diagnosing failures: `error` ≠ `failure`

The two pipeline statuses look similar but mean different things and require different tools.

- **`failure`** — a step ran and exited non-zero. Use `woodpecker-cli pipeline ps <repo> <n>` to see which step, then `woodpecker-cli pipeline log show <repo> <n> <step-number>` for the output.
- **`error`** — Woodpecker rejected the pipeline at config-parse or scheduling time. There are no steps, so `pipeline ps` returns nothing useful and there are no logs to fetch. The CLI's `pipeline show` does **not** display the error message either.

To get the actual error message for `error`-status pipelines, hit the REST API directly. Look up the numeric repo ID first (the slug doesn't work in API paths):

```bash
# Find the repo's numeric id
curl -sS -H "Authorization: Bearer $WOODPECKER_TOKEN" \
  "$WOODPECKER_SERVER/api/repos/lookup/<owner>/<name>" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])'

# Then read the pipeline's errors array
curl -sS -H "Authorization: Bearer $WOODPECKER_TOKEN" \
  "$WOODPECKER_SERVER/api/repos/<id>/pipelines/<n>" \
  | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)["errors"], indent=2))'
```

Common error messages and what they mean:
- `"unable to parse variable name"` — bare `$word` form Woodpecker can't resolve. See variable interpolation section above.
- `"missing closing brace"` — confused `${...}` parse, often from `$${VAR}`.
- `"no agent for the pipeline"` — `labels:` filter doesn't match any agent's `custom_labels`. Note that label values are compared **literally**: `darwin/*` on the agent side is a literal 7-char string, not a glob; `*` only acts as a wildcard when it's the **entire** value.

## Local backend gotchas (Mac/Linux agents, no Docker)

The local backend (used when the agent runs commands directly on a host, e.g. for iOS or macOS work) has behaviors that differ from the Docker backend:

- **`$HOME` is sandboxed per-pipeline.** Woodpecker sets `$HOME` to an ephemeral path under the agent's cache dir (`~/.cache/woodpecker-agent/<run>/home`). Anything that depends on the user's real home — login keychain, `~/.ssh/`, `~/.appstoreconnect/`, sops-nix-decrypted secrets — will not be found. Re-resolve the real home in every step that needs it:
  ```bash
  export HOME=$(dscl . -read /Users/$(whoami) NFSHomeDirectory | awk '{print $2}')
  test -d "$HOME" || { echo "could not resolve real user home" >&2; exit 1; }
  ```
- **Each `- command:` entry runs in a separate bash invocation.** `export` in one entry does **not** carry to the next. If you need a variable to span the work, fold everything into a single `|` block scalar or set it via the step's `environment:` map.
- **No GUI session.** Anything that requires `loginwindow` to have unlocked the keychain (signing identities, code-signing private key access) needs explicit `security unlock-keychain -p <pw> ~/Library/Keychains/login.keychain-db` and `security default-keychain -s …` first. The keychain password has to come from a Woodpecker secret because it's the user's macOS login password — host-specific, not repo-specific, and not a thing other contributors should ever see.
- **`per-step environment:` is the only sane way to inject secrets into commands** — see variable interpolation section above for why.

## Secrets: three places, three reasons

| Storage | When to use | Example |
| --- | --- | --- |
| **Woodpecker repo secrets** (UI / `repo secret add`) | Host-specific or pipeline-only credentials that don't belong to the repo's dev environment. | macOS login password (for keychain unlock). |
| **sops-nix in the dev shell** | Repo-level credentials that interactive devs also use, loaded via `flake.nix` shellHook. The shellHook should silently no-op on machines without the secrets so the dev shell still works for new contributors. | App Store Connect API key ID + issuer ID. |
| **On-disk on the agent host, not managed at all** | Things that are bound to the agent's identity rather than the repo or the user's secrets store. | App Store Connect `.p8` key file at `~/.appstoreconnect/private_keys/`, signing identities in the login keychain, SSH keys. |

When migrating credentials *out* of a Woodpecker secret and *into* sops-nix-via-shellHook, audit the shellHook for unconditional `export VAR=...` statements. Those clobber any value Woodpecker injects, defeating the migration. The fix is to make the export conditional: `: "${VAR:=$(cat …)}"` only sets the var if unset.

## Pushing back from a step (commit-bump, tag, etc.)

The clone step sets `origin` to an HTTPS URL with read-only token auth. Trying to `git push origin …` from a later step fails with `could not read Username for 'https://…': Device not configured` — the token has no push perms and there is no credential helper.

Re-URL `origin` to SSH before pushing, so the agent's `~/.ssh/` keys (after the HOME re-resolve above) authenticate the push:

```bash
git remote set-url origin git@<host>:<owner>/<repo>.git
git push origin HEAD:master
```

This requires the agent user to have an SSH key registered with the forge's user account. Verify with `ssh -o BatchMode=yes -T git@<host>` before adding the push step.

## iOS signing on a non-interactive Mac agent

The single hardest path Woodpecker has to support on Apple platforms. Several traps that aren't documented anywhere obvious:

- **Cloud-managed signing does NOT work via App Store Connect API key on Individual Apple Developer teams.** The "Access to Cloud Managed Distribution Certificate" checkbox is not exposed when generating an API key on Individual accounts; a key created without it (and you can't add it later) hits `"Cloud signing permission error"` followed by `"No signing certificate iOS Distribution found"` even though the team has an Apple Distribution cert in the cloud. Apple-ID-auth via Xcode → Settings → Accounts can use cloud signing on Individual; API-key auth cannot.
- **The fix is manual signing.** Generate a regular Apple Distribution cert (CSR via Keychain Access → Certificate Assistant → "Request a Certificate from a Certificate Authority…", "Saved to disk"), upload to Apple Developer portal, download the `.cer`, import via `security import <cer> -k login.keychain-db` (the **iCloud** keychain rejects code-signing certs with error -25294). Create a matching App Store provisioning profile referencing that cert. Reference both by name in `ExportOptions.plist` with `signingStyle: manual`, `signingCertificate: "Apple Distribution"`, `provisioningProfiles: { <bundle-id>: "<profile-name>" }`.
- **Provisioning profiles install at the post-Xcode-16 location:** `~/Library/Developer/Xcode/UserData/Provisioning Profiles/<UUID>.mobileprovision`, NOT the legacy `~/Library/MobileDevice/Provisioning Profiles/`. Double-clicking a `.mobileprovision` file in the new Xcode silently installs to the new location with no visible feedback.
- **The first interactive `codesign` invocation against a freshly-imported private key prompts for keychain access; click "Always Allow" once.** This adds `codesign` to the private key's ACL, which persists in the keychain item itself (not session state) and applies to non-interactive runs from then on. Without this step, CI's codesign call fails silently with no useful error.
- **`PlistBuddy` strips XML comments when it saves.** If your `Info.plist` has comments documenting why a setting is the way it is, `PlistBuddy -c "Set …"` deletes them on every bump. Use `perl -0pi -e 's|(<key>NAME</key>\s*<string>)\d+(</string>)|${1}NEW_VALUE${2}|' Info.plist` for in-place byte-level edits that preserve comments.
- **xcodebuild's `-allowProvisioningUpdates` plus `-authenticationKey*` flags force the API-key auth path** — useful in some CI configs, but on Individual teams this kicks the build into the cloud-signing failure mode. With manual signing in `ExportOptions.plist`, you don't need the auth flags on the export step at all.

## Quick reference: triggering manually

- **UI:** the repo page → "Run Pipeline" → pick branch → submit. Only workflows with `event: manual` in `when:` will fire.
- **CLI:** `woodpecker-cli pipeline create <owner>/<name> --branch <branch>`. Authentication via `WOODPECKER_SERVER` + `WOODPECKER_TOKEN` env vars or `~/.config/woodpecker/config.yaml`.
- **Lint locally before pushing:** `woodpecker-cli lint .woodpecker/<file>`. Catches schema issues but **not** templating issues — those only surface at server scheduling time.
- **Run a pipeline file end-to-end on the local machine:** `woodpecker-cli exec --backend local .woodpecker/<file>`. Useful for testing archive flows, but the upload step will really talk to App Store Connect if creds are present, so stub or skip that step when exec'ing.
