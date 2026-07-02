export const meta = {
  name: 'colmena-deploy',
  description: 'Sequentially deploy every colmena host, verifying fleet web health after each switch',
  whenToUse: 'Full-fleet colmena deployment: applies hosts one at a time in canonical order (stormwind, ironforge, orgrimmar, anton, gnomeregan, headscale/gateway), verifies every web site in the fleet after each successful switch, fixes what breaks, and restarts the sequence from stormwind when a switch fails. Audits WORKAROUND-tagged overrides against the pinned unstable rev before deploying. Unreachable machines are skipped — a down host never blocks the rest of the fleet.',
  phases: [
    { title: 'Pre-flight', detail: 'repo sanity + host reachability', model: 'ollama/qwen3.6:35b' },
    { title: 'Workaround Audit', detail: 'retire stale WORKAROUND overrides against the pinned unstable rev', model: 'openrouter/openai/gpt-5.5' },
    { title: 'Deploy', detail: 'colmena apply, one host at a time, in canonical order', model: 'ollama/qwen3.6:35b' },
    { title: 'Verify', detail: 'curl every fleet web site after each switch', model: 'ollama/qwen3.6:35b' },
    { title: 'Fix', detail: 'diagnose/fix a failed switch, then restart from stormwind', model: 'openrouter/openai/gpt-5.5' },
    { title: 'Heal', detail: 'fix unhealthy sites before advancing to the next host', model: 'openrouter/openai/gpt-5.5' },
  ],
}

const SMALL_MODEL = 'ollama/qwen3.6:35b'
const DEEP_MODEL = 'openrouter/openai/gpt-5.5'

// Canonical deploy order. "gateway" is the colmena node named `headscale`.
const ORDER = ['stormwind', 'ironforge', 'orgrimmar', 'anton', 'gnomeregan', 'headscale']
const MAX_RESTARTS = 3 // full restarts of the sequence after switch-failure fixes
const MAX_HEAL_ROUNDS = 3 // heal attempts per host visit before aborting
// Endpoint counts per host, mirroring the Web Endpoints tables in
// references/host-mapping.md — update BOTH together. Used to compute the
// verification coverage floor (a verifier returning far fewer probes than the
// non-skipped hosts' total has under-probed, e.g. only checked one host).
const ENDPOINT_COUNTS = { stormwind: 2, ironforge: 9, orgrimmar: 8, anton: 0, gnomeregan: 1, headscale: 1 }

const REPO = '/Users/fdrake/nix'
const INFRA_SKILL_DIR = `${REPO}/apps/agent-common/skills/infrastructure`
const ENDPOINTS_DOC = `${INFRA_SKILL_DIR}/references/host-mapping.md`

const HOST_NOTES = {
  stormwind: `stormwind is a Hetzner dedicated box (ssh port 2222, root). Runs the traceway
observability stack and gatus; traceway's container is pulled from gitea's registry on orgrimmar.`,
  ironforge: `ironforge is a Hetzner dedicated box (ssh port 2222, root). Heavy podman media
stack — activation can take a while when many containers restart.`,
  orgrimmar: `orgrimmar is a Hetzner dedicated box (ssh port 2222, root) running gitea,
woodpecker, paperless, calibre-web, filebrowser, and the resume site.`,
  anton: `anton is WSL NixOS on a Windows laptop, deployed as the \`nixos\` user via sudo.
KNOWN QUIRK: on systemd major-version bumps colmena can exit 4 with a user dbus-broker reload
timeout even though the switch SUCCEEDED — always verify the active generation over ssh before
declaring failure; if the built path is active, report switched=true.
If anton is unreachable, the usual cause is the Windows laptop being asleep or off — report
that plainly rather than hunting for a config problem.`,
  gnomeregan: `gnomeregan is a home-LAN box on Wi-Fi, deployed as \`fdrake\` via sudo. It tracks
nixpkgs-unstable, so builds can be much larger than on the stable hosts, and it runs the full
workstation home-manager stack (long activation is normal).`,
  headscale: `headscale (the box your operator calls "gateway") is a Hetzner VPS (ssh alias
"headscale" → 10.1.1.2, root, port 22). Its critical role is tailscale SUBNET ROUTER for the
Hetzner private net 10.1.0.0/16 — breaking it cuts tailnet reachability of every 10.1.1.x web
endpoint on stormwind/ironforge/orgrimmar, so treat activation failures here as urgent. The
headscale daemon it runs is a vestigial empty-DB instance (the live control plane is
headscale.brainrush.ai, managed in a separate repo): keep nginx, /health, and the tailscale
client healthy; do not debug the daemon's registration features.`,
}

const PREFLIGHT_SCHEMA = {
  type: 'object',
  required: ['ok', 'blockers', 'unreachable'],
  properties: {
    ok: { type: 'boolean', description: 'true if there are no blockers (unreachable hosts are skipped, they do not block)' },
    blockers: { type: 'array', items: { type: 'string' }, description: 'repo-state problems that would break the deploy' },
    unreachable: { type: 'array', items: { type: 'string' }, description: 'hosts that failed the ssh reachability check' },
    notes: { type: 'string' },
  },
}

const DEPLOY_SCHEMA = {
  type: 'object',
  required: ['host', 'switched'],
  properties: {
    host: { type: 'string' },
    switched: { type: 'boolean', description: 'true ONLY if the new generation is verified active on the host' },
    unreachable: { type: 'boolean', description: 'true if the failure is the host being down/unreachable (ssh cannot connect at all), not a config/build/activation problem' },
    generation: { type: 'string', description: 'the active /run/current-system store path after the switch' },
    failureStage: { type: 'string', description: 'eval | build | push | activation | ssh | unknown — empty if switched' },
    rootCause: { type: 'string', description: 'the specific error lines, not the whole log' },
  },
}

const PROBE_SCHEMA = {
  type: 'object',
  required: ['results'],
  properties: {
    results: {
      type: 'array',
      items: {
        type: 'object',
        required: ['url', 'host', 'status', 'ok'],
        properties: {
          url: { type: 'string' },
          host: { type: 'string', description: 'which physical host serves this URL' },
          status: { type: 'string', description: 'final HTTP status after redirects, or dns-failure/timeout/connection-refused' },
          ok: { type: 'boolean' },
          detail: { type: 'string' },
        },
      },
    },
    notes: { type: 'string', description: 'fleet-wide signatures, e.g. all *.internal names failing DNS at once' },
  },
}

const FIX_SCHEMA = {
  type: 'object',
  required: ['fixed', 'summary'],
  properties: {
    fixed: { type: 'boolean', description: 'true only if the root cause is addressed AND verified' },
    summary: { type: 'string', description: 'what was wrong and what was done' },
    changedFiles: { type: 'array', items: { type: 'string' }, description: 'repo files edited, if any' },
  },
}

const AUDIT_SCHEMA = {
  type: 'object',
  required: ['markers', 'summary'],
  properties: {
    markers: {
      type: 'array',
      items: {
        type: 'object',
        required: ['pkg', 'verdict'],
        properties: {
          pkg: { type: 'string', description: 'the package named in the WORKAROUND(<pkg>) marker' },
          file: { type: 'string', description: 'file containing the marker' },
          verdict: {
            type: 'string',
            description: 'removed | kept | manual — removed: stock build green at the pinned rev, override deleted; kept: stock build still fails, override still needed; manual: not testable by a nixpkgs build (e.g. a container digest hold) — reported untouched',
          },
          reason: { type: 'string' },
        },
      },
    },
    changedFiles: { type: 'array', items: { type: 'string' }, description: 'repo files edited (override removals)' },
    summary: { type: 'string' },
  },
}

const HEAL_SCHEMA = {
  type: 'object',
  required: ['fixed', 'summary'],
  properties: {
    fixed: { type: 'boolean', description: 'true only if every previously-failing URL was re-curled healthy, OR the only remaining step is the redeploys listed in redeployHosts (config verified with colmena build)' },
    summary: { type: 'string', description: 'what was wrong and what was done' },
    changedFiles: { type: 'array', items: { type: 'string' }, description: 'repo files edited, if any' },
    redeployHosts: { type: 'array', items: { type: 'string' }, description: 'colmena hosts that must be re-applied for the fix to take effect; the workflow performs and verifies these applies itself' },
    unreachableHosts: { type: 'array', items: { type: 'string' }, description: 'owning hosts that are DOWN (ssh cannot connect at all — machine off/asleep), making their sites unfixable; the workflow skips down machines' },
  },
}

const deployPrompt = host => `You are deploying the NixOS host "${host}" via colmena from the
flake repo at ${REPO}.

Run, watching it to completion (the output is long — that is why you exist):
  cd ${REPO} && colmena apply --on ${host} --impure
(--impure is required by this project; this is what \`just colmena ${host}\` runs.)

Then verify activation INDEPENDENTLY of the exit code:
  ssh ${host} 'readlink /run/current-system'
and compare it against the system path colmena built/pushed for this host.

Host notes:
${HOST_NOTES[host]}

Report switched=true ONLY if the new generation is active on the host. On failure, classify
failureStage (eval|build|push|activation|ssh|unknown) and extract the actual root-cause lines,
not the whole log. If the host is simply DOWN (ssh cannot connect at all — machine off, asleep,
or unroutable), report switched=false with unreachable=true: the workflow skips down machines
instead of treating them as deploy failures. Return raw data only — your final message is
parsed, not read by a human.`

const verifyPrompt = (host, skippedHosts) => `Host "${host}" just switched successfully via
colmena. Now verify the WHOLE fleet's web sites.

1. FIRST run \`tailscale status\` on this machine. *.internal.freddrake.com only resolves over
   the tailnet, and a stopped local tailscaled looks exactly like a fleet-wide outage. If it
   reports stopped, run \`tailscale up\`, confirm it connects, then proceed.
2. Read the "Web Endpoints" tables in ${ENDPOINTS_DOC} — that file is the source of truth for
   which URLs must be healthy, what status each is expected to return, and the special probe
   forms (gitea-status uses /health; the headscale/"gateway" check probes https://10.1.1.2/health
   via private IP, pinning the vhost with an explicit Host header).
3. Probe EVERY URL in those tables — do not stop at the just-deployed host. For each URL run:
     curl -skL -o /dev/null -w '%{http_code}' --max-time 20 '<url>'
   ok=true only if the FINAL status (after redirects) matches the table's expected status
   (default: any 2xx).
${skippedHosts.length ? `
SKIPPED HOSTS: ${skippedHosts.join(', ')} — unreachable this run and deliberately skipped.
Do NOT probe their endpoint tables and do not report results for them; they are excluded
from this verification.
` : ''}
In each result, the "host" field must be the exact colmena node name serving that URL
(stormwind, ironforge, orgrimmar, anton, gnomeregan, or headscale).

Known fleet-wide signature: if EVERY *.internal.freddrake.com name still fails DNS with local
tailscale up, the internal DNS resolver (hearthstone, 100.64.0.13) or the headscale subnet
router is the problem — say so in notes instead of just marking every site broken.

Return raw data only: one result per URL with its serving host, final status, and ok.`

const auditPrompt = builder => `Audit this repo's temporary package workarounds before a
full-fleet colmena deployment from ${REPO}. The unstable hosts (anton, gnomeregan) are about to
be rebuilt against the pinned nixpkgs-unstable rev — exactly when stale overrides rot. The
authoritative procedure is the "Workaround Hygiene" section of
${INFRA_SKILL_DIR}/SKILL.md — read it first.

In brief:
1. \`grep -rn 'WORKAROUND(' ${REPO} --exclude-dir=.git\`. No markers → markers=[], done.
2. For each marker under overlays/: get the pinned rev with
     REV=$(jq -r '.nodes["nixpkgs-unstable"].locked.rev' ${REPO}/flake.lock)
   then build the STOCK package (override absent) on ${builder}, a reachable unstable
   x86_64-linux host:
     ssh ${builder} "NIXPKGS_ALLOW_UNFREE=1 nix build --no-link -L --impure github:nixos/nixpkgs/$REV#<pkg>"
   - Builds or substitutes clean → upstream is fixed at this rev: DELETE the override and its
     marker (and its reference in overlays/default.nix if you remove a whole file — \`git rm\`
     deleted files so the git+file flake doesn't half-see them). Then confirm the consuming
     config still evaluates: \`colmena build --on ${builder} --impure\` from ${REPO} must
     succeed. Verdict: removed. If that build fails, RESTORE the override and report kept.
   - Stock build fails → workaround still needed; change nothing. Verdict: kept.
3. Markers OUTSIDE overlays/ (e.g. container digest holds in apps/fetcher/) are not testable by
   a nixpkgs build — do NOT modify them; report verdict=manual with the marker's stated removal
   condition so the operator sees it.
4. Touch ONLY WORKAROUND-tagged overrides. Intentional pins (glance, woodpecker-agent, the
   spotify darwin src) are NOT workarounds — leave them alone even if they look stale.

This audit is advisory and must not wedge the deploy: when in doubt, keep the override and say
why rather than guessing. Return raw data only.`

const switchFixPrompt = (host, deploy) => `Deploying NixOS host "${host}" with
\`colmena apply --on ${host} --impure\` from ${REPO} FAILED.

Failure stage: ${deploy.failureStage || 'unknown'}
Root cause reported by the deploy agent:
${deploy.rootCause || '(none captured — investigate from scratch)'}

Host notes:
${HOST_NOTES[host]}

Diagnose and FIX the root cause:
- Config/eval/build bugs → fix the nix code in ${REPO}. Repo conventions: temporary overlay
  overrides get a "# WORKAROUND(<pkg>): <reason>; remove when <condition>." marker; \`git add\`
  any NEW file (the git+file flake cannot see untracked files); read
  ${INFRA_SKILL_DIR}/references/gnomeregan.md before touching gnomeregan's config.
- Remote-state problems (disk full, wedged unit, unreachable ssh) → fix over ssh. Hetzner hosts
  ssh as root (stormwind/ironforge/orgrimmar port 2222, headscale port 22); anton as nixos@ with
  sudo; gnomeregan as fdrake@ with sudo. If a disk is mysteriously full, check coredumpctl for a
  crash-looping unit spraying core dumps.
- No fallbacks, no masking — fix root causes only.

Verify the fix: for config fixes run \`colmena build --on ${host} --impure\` and confirm it
succeeds; for remote-state fixes re-check the state you repaired. Do NOT run \`colmena apply\`
yourself — after you report, the deployment sequence restarts from stormwind and re-applies.

Report fixed=true only if you verified the root cause is addressed. Return raw data only.`

const healPrompt = (host, failing, notes) => `During a sequential fleet deployment (currently at
host "${host}", which switched successfully), these web sites are failing verification:

${JSON.stringify(failing, null, 2)}
${notes ? `\nVerifier notes: ${notes}\n` : ''}
The deployment may NOT advance until every fleet site returns its expected status. Diagnose and
fix them.

Toolbox / known failure modes:
- ssh <owning-host> 'systemctl status <svc>', 'journalctl -u <svc> -n 100', restart units.
  Hetzner hosts ssh as root (stormwind/ironforge/orgrimmar port 2222, headscale port 22);
  anton as nixos@ with sudo; gnomeregan as fdrake@ with sudo.
- Containers: 'podman ps -a' and container unit logs on the owning host.
- ALL *.internal.freddrake.com names failing DNS at once → first re-check \`tailscale status\`
  on THIS machine (a stopped local tailscaled mimics a fleet outage; \`tailscale up\` fixes it).
  If local tailscale is up, hearthstone's tailscaled (OpenWRT router, 492MB RAM) has likely been
  OOM-killed: ssh hearthstone '/etc/init.d/tailscale restart'.
- Service down + disk full → check coredumpctl for a crash-looping unit filling the disk.
- If the root cause is a nix config bug, fix it in ${REPO} (conventions: WORKAROUND markers for
  temporary overlay overrides; \`git add\` new files; read
  ${INFRA_SKILL_DIR}/references/gnomeregan.md before touching gnomeregan's
  config), then verify with \`colmena build --on <owning-host> --impure\` and list the host in
  redeployHosts. Do NOT run \`colmena apply\` yourself — the workflow performs and verifies
  every apply itself.
- Do NOT mask failures: no removing checks, no stub pages, no fake 200s.
- If a failing site's owning host is itself DOWN (ssh cannot connect at all — machine off or
  asleep), do not fight it: list that host in unreachableHosts. The workflow skips down
  machines rather than letting one block the whole fleet (a host that switched earlier in THIS
  run and then went dark is the exception — the workflow treats that as possible deploy fallout
  and keeps diagnosing, so still report it and what you observed).

After fixing, re-curl every previously-failing URL and confirm its expected status. Report
fixed=true only if ALL of them are confirmed healthy, or if the only remaining failures belong
to hosts you listed in unreachableHosts / the redeploys you listed in redeployHosts. Return raw
data only.`

// ── Shared mechanics ─────────────────────────────────────────────────────────
let restarts = 0
const timeline = []

async function runDeploy(host, label) {
  const d = await agent(deployPrompt(host), {
    label, phase: 'Deploy', schema: DEPLOY_SCHEMA, model: SMALL_MODEL,
  })
  if (!d) throw new Error(`deploy agent for ${host} returned no result`)
  return d
}

// On a failed switch: record it, enforce the restart cap BEFORE spending a fix
// agent, run the fix, and signal either 'restart' (from stormwind) or 'abort'.
async function fixSwitchFailure(host, deploy) {
  timeline.push({ host, event: 'switch-failed', stage: deploy.failureStage, rootCause: deploy.rootCause })
  if (restarts >= MAX_RESTARTS) {
    return {
      action: 'abort',
      payload: {
        status: 'aborted',
        reason: `${host} failed to switch and the ${MAX_RESTARTS}-restart cap is already exhausted — not attempting another fix. Manual intervention required.`,
        rootCause: deploy.rootCause,
        timeline,
      },
    }
  }
  const fix = await agent(switchFixPrompt(host, deploy), {
    label: `fix-switch:${host}`, phase: 'Fix', schema: FIX_SCHEMA, model: DEEP_MODEL,
  })
  if (!fix) throw new Error(`fix agent for ${host} returned no result`)
  timeline.push({ host, event: 'switch-fix', fixed: fix.fixed, summary: fix.summary, changedFiles: fix.changedFiles })
  if (!fix.fixed) {
    return {
      action: 'abort',
      payload: {
        status: 'aborted',
        reason: `${host} failed to switch and the fix attempt did not converge — manual intervention required.`,
        rootCause: deploy.rootCause,
        fixSummary: fix.summary,
        timeline,
      },
    }
  }
  restarts++
  return { action: 'restart' }
}

// ── Pre-flight ───────────────────────────────────────────────────────────────
const preflight = await agent(
  `Pre-flight a full-fleet colmena deployment from ${REPO}. Do NOT fix anything — report only.

1. Run \`git -C ${REPO} status --porcelain\` and list any UNTRACKED (??) *.nix files. The flake
   is evaluated as git+file with --impure: untracked nix files are invisible to the deploy and
   cause "path does not exist" eval failures. Each one is a blocker.
2. Confirm the \`colmena\` binary is available (\`colmena --version\`).
3. Reachability: for each of ${ORDER.join(', ')} run
   \`ssh -o ConnectTimeout=10 -o BatchMode=yes <host> true\` and list hosts that fail.
   Unreachable hosts are NOT blockers — the deploy skips them and continues with the rest
   (anton is a Windows laptop and is often asleep or off).

Return raw data only.`,
  { label: 'pre-flight', phase: 'Pre-flight', schema: PREFLIGHT_SCHEMA, model: SMALL_MODEL }
)
if (!preflight) throw new Error('pre-flight agent returned no result')
const blockers = preflight.blockers || []
const unreachable = preflight.unreachable || []
if (blockers.length > 0 || (!preflight.ok && unreachable.length === 0)) {
  return {
    status: 'aborted',
    reason: 'Pre-flight failed — fix these before deploying.',
    blockers,
    unreachable,
    notes: preflight.notes,
    timeline,
  }
}

// Unreachable machines are skipped, never blocking: a down laptop must not
// hold up the rest of the fleet. Their endpoints are excluded from the
// health gate and they are reported under `skipped` in the result.
const skipped = new Set()
const deployedThisRun = new Set() // hosts that switched at least once this run
// Verifier results may use the operator's "gateway" alias or odd casing.
const nodeName = s => {
  const n = String(s || '').toLowerCase().trim()
  return n === 'gateway' ? 'headscale' : n
}
for (const h of unreachable) {
  if (ORDER.includes(h)) skipped.add(h)
}
if (skipped.size > 0) {
  log(`Skipping unreachable host(s): ${[...skipped].join(', ')}`)
  for (const h of skipped) timeline.push({ host: h, event: 'skipped-unreachable', when: 'pre-flight' })
}
if (skipped.size === ORDER.length) {
  return { status: 'aborted', reason: 'Every host is unreachable — nothing to deploy.', unreachable, timeline }
}

// ── Workaround hygiene audit ─────────────────────────────────────────────────
// The fleet deploy rebuilds the unstable hosts from the pinned nixpkgs-unstable
// rev — the moment stale WORKAROUND overrides rot. Audit them per SKILL.md's
// "Workaround Hygiene" before deploying. Advisory: it retires dead overrides
// but never blocks the run. Needs an unstable x86_64-linux host to build stock
// packages on (gnomeregan preferred; anton is often asleep).
const auditBuilder = ['gnomeregan', 'anton'].find(h => !skipped.has(h))
if (!auditBuilder) {
  log('Workaround audit skipped — no unstable x86_64-linux host reachable to build stock packages on')
  timeline.push({ event: 'workaround-audit-skipped', reason: 'no reachable unstable host' })
} else {
  const audit = await agent(auditPrompt(auditBuilder), {
    label: 'workaround-audit', phase: 'Workaround Audit', schema: AUDIT_SCHEMA, model: DEEP_MODEL,
  })
  if (!audit) {
    log('Workaround audit agent returned no result — continuing without the audit')
    timeline.push({ event: 'workaround-audit-skipped', reason: 'audit agent returned no result' })
  } else {
    timeline.push({ event: 'workaround-audit', markers: audit.markers, changedFiles: audit.changedFiles, summary: audit.summary })
    const removed = (audit.markers || []).filter(m => m.verdict === 'removed')
    log(removed.length
      ? `Workaround audit: retired ${removed.length} stale override(s): ${removed.map(m => m.pkg).join(', ')}`
      : `Workaround audit: ${(audit.markers || []).length} marker(s) checked, none retired`)
  }
}

// ── Sequential deploy loop ───────────────────────────────────────────────────
let i = 0

while (i < ORDER.length) {
  const host = ORDER[i]
  if (skipped.has(host)) {
    i++
    continue
  }
  log(`Deploying ${host} (${i + 1}/${ORDER.length}${restarts ? `, restart ${restarts}/${MAX_RESTARTS}` : ''})`)

  const deploy = await runDeploy(host, `deploy:${host}`)
  if (!deploy.switched) {
    if (deploy.unreachable) {
      log(`${host} is unreachable — skipping it; the rest of the fleet continues`)
      timeline.push({ host, event: 'skipped-unreachable', when: 'deploy', rootCause: deploy.rootCause })
      skipped.add(host)
      i++
      continue
    }
    log(`${host} FAILED to switch (${deploy.failureStage || 'unknown'}) — fixing, then restarting from ${ORDER[0]}`)
    const outcome = await fixSwitchFailure(host, deploy)
    if (outcome.action === 'abort') return outcome.payload
    i = 0
    continue
  }
  timeline.push({ host, event: 'switched', generation: deploy.generation })
  deployedThisRun.add(host)

  // Fleet-wide site verification: up to MAX_HEAL_ROUNDS heals, probe after each.
  // Health is derived from per-URL results only, with a coverage floor so a
  // lazy/truncated verifier cannot pass vacuously.
  let healthy = false
  let restartFromTop = false
  let underProbes = 0
  for (let round = 0; round <= MAX_HEAL_ROUNDS; ) {
    const probe = await agent(verifyPrompt(host, [...skipped]), {
      label: `verify:${host}#${round + 1}`, phase: 'Verify', schema: PROBE_SCHEMA, model: SMALL_MODEL,
    })
    if (!probe) throw new Error(`verify agent after ${host} returned no result`)

    // Coverage floor over the non-skipped hosts' endpoint tables (70% slack
    // tolerates small doc drift but catches a one-host-only verifier).
    const expectedProbes = ORDER.filter(h => !skipped.has(h)).reduce((n, h) => n + ENDPOINT_COUNTS[h], 0)
    const minProbes = Math.ceil(expectedProbes * 0.7)
    if (probe.results.length < minProbes) {
      underProbes++
      if (underProbes > 1) {
        return {
          status: 'aborted',
          reason: `Verifier malfunction after ${host}: only ${probe.results.length} URL probes returned (expected >= ${minProbes} for the non-skipped hosts' Web Endpoints tables), twice in a row.`,
          timeline,
        }
      }
      log(`Verifier under-probed after ${host} (${probe.results.length} results, expected >= ${minProbes}) — re-probing`)
      continue // does not consume a heal round
    }
    underProbes = 0 // coverage OK — only consecutive under-probes count as malfunction

    const failing = probe.results.filter(r => !r.ok && !skipped.has(nodeName(r.host)))
    if (failing.length === 0) {
      healthy = true
      break
    }
    if (round === MAX_HEAL_ROUNDS) {
      timeline.push({ host, event: 'sites-unhealthy', failing })
      break
    }

    log(`${failing.length} site(s) unhealthy after ${host} — heal round ${round + 1}/${MAX_HEAL_ROUNDS}`)
    const heal = await agent(healPrompt(host, failing, probe.notes), {
      label: `heal:${host}#${round + 1}`, phase: 'Heal', schema: HEAL_SCHEMA, model: DEEP_MODEL,
    })
    if (!heal) throw new Error(`heal agent after ${host} returned no result`)
    timeline.push({ host, event: 'heal-attempt', round: round + 1, failing: failing.map(f => f.url), fixed: heal.fixed, result: heal.summary })

    // Hosts the heal agent found down are skipped — unless they switched
    // earlier this run, in which case the outage may be deploy fallout and
    // stays on the diagnose/abort path.
    for (const raw of heal.unreachableHosts || []) {
      const uh = nodeName(raw)
      if (!ORDER.includes(uh) || skipped.has(uh)) continue
      if (deployedThisRun.has(uh)) {
        log(`${uh} reported unreachable but it switched earlier this run — not skipping (possible deploy fallout)`)
        continue
      }
      log(`${uh} is unreachable — skipping it; the rest of the fleet continues`)
      timeline.push({ host: uh, event: 'skipped-unreachable', when: 'heal', rootCause: 'owning host down during fleet verification' })
      skipped.add(uh)
    }

    // Heal-requested redeploys run through the loop's own Deploy mechanics so
    // every switch is verified and a failed one restarts the sequence.
    let redeployFailure = null
    for (const raw of heal.redeployHosts || []) {
      const rh = nodeName(raw)
      if (!ORDER.includes(rh) || skipped.has(rh)) {
        log(`Heal requested redeploy of ${ORDER.includes(rh) ? 'skipped' : 'unknown'} host "${raw}" — ignoring`)
        continue
      }
      log(`Heal requires redeploy of ${rh}`)
      const redeploy = await runDeploy(rh, `redeploy:${rh}`)
      if (!redeploy.switched) {
        if (redeploy.unreachable && !deployedThisRun.has(rh)) {
          log(`${rh} is unreachable — skipping it; the rest of the fleet continues`)
          timeline.push({ host: rh, event: 'skipped-unreachable', when: 'heal-redeploy', rootCause: redeploy.rootCause })
          skipped.add(rh)
          continue
        }
        redeployFailure = { host: rh, deploy: redeploy }
        break
      }
      timeline.push({ host: rh, event: 'redeployed-during-heal', generation: redeploy.generation })
      deployedThisRun.add(rh)
    }
    if (redeployFailure) {
      log(`${redeployFailure.host} FAILED to switch during heal — fixing, then restarting from ${ORDER[0]}`)
      const outcome = await fixSwitchFailure(redeployFailure.host, redeployFailure.deploy)
      if (outcome.action === 'abort') return outcome.payload
      restartFromTop = true
      break
    }
    round++
  }

  if (restartFromTop) {
    i = 0
    continue
  }
  if (!healthy) {
    return {
      status: 'aborted',
      reason: `Fleet site checks failed to converge after ${MAX_HEAL_ROUNDS} heal rounds following ${host}'s deploy.`,
      timeline,
    }
  }
  timeline.push({ host, event: 'fleet-verified' })
  log(`${host} deployed and fleet verified healthy`)
  i++
}

const hostsDeployed = ORDER.filter(h => deployedThisRun.has(h) && !skipped.has(h))
return {
  status: hostsDeployed.length === 0 ? 'nothing-deployed' : skipped.size > 0 ? 'partial' : 'success',
  hostsDeployed,
  skipped: [...skipped],
  restarts,
  timeline,
}
