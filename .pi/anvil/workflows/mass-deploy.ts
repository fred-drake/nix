import { existsSync, readFileSync } from "node:fs";

const REPO = "/Users/fdrake/nix";
const INFRA_SKILL = `${REPO}/.pi/skills/infrastructure/SKILL.md`;
const HOST_MAPPING = `${REPO}/.pi/skills/infrastructure/references/host-mapping.md`;
const STATE_FILE = "/tmp/anvil-mass-deploy-state.json";
const ORDER = ["stormwind", "ironforge", "orgrimmar", "anton", "gnomeregan", "headscale"];
const ORDER_LABEL = "stormwind → ironforge → orgrimmar → anton → gnomeregan → headscale/gateway";
const SSH_ALIAS_GUIDANCE = `Use the user's ~/.ssh/config Host aliases exactly: ${ORDER.join(", ")}.
Do not bypass SSH config by spelling out raw IPs, *.internal.freddrake.com names, user@host, or explicit ports.
Examples: use \`ssh anton ...\` and \`ssh gnomeregan ...\`, not FQDNs or user-qualified targets.`;

function skippedHost(host: string): boolean {
	try {
		if (!existsSync(STATE_FILE)) return false;
		const state = JSON.parse(readFileSync(STATE_FILE, "utf8")) as { skippedHosts?: string[] };
		return Array.isArray(state.skippedHosts) && state.skippedHosts.includes(host);
	} catch {
		return false;
	}
}

function deployStep(host: string, title: string, hostNotes: string) {
	return {
		id: `deploy-${host}`,
		title,
		skipIf: () => skippedHost(host),
		prompt: `Deploy ${host} as part of the mass-deploy workflow.

Read ${INFRA_SKILL} and follow the full-fleet deployment contract. Current canonical order: ${ORDER_LABEL}.

SSH targeting:
${SSH_ALIAS_GUIDANCE}

Host notes:
${hostNotes}

State file: ${STATE_FILE}
- Read this file before probing health.
- If this host is unreachable, add it to skippedHosts if it is not already present, record an event, end with status SKIPPED_UNREACHABLE, and do not treat that as a failure.
- For all fleet health checks, exclude endpoints owned by hosts listed in skippedHosts.

Deploy rules for this host:
1. First check SSH reachability with \`ssh -o BatchMode=yes -o ConnectTimeout=10 ${host} 'true'\`. If unreachable, update ${STATE_FILE}, report SKIPPED_UNREACHABLE, and stop this step successfully.
2. Run from ${REPO}: colmena apply --on ${host} --impure.
3. Do not run a parallel, comma-separated, or all-host colmena apply.
4. Independently verify activation with \`ssh ${host} 'readlink /run/current-system'\` and compare it to the built/pushed system path. For anton, remember that exit code 4 can be a spurious user dbus-broker reload timeout; verify the active generation before deciding it failed.
5. If eval/build/push/activation fails for a real reason, diagnose and fix the root cause. Fix Nix repository problems in ${REPO}; git add any new files. Fix remote-state problems over SSH. Do not mask failures.
6. If you fixed any failure, still finish the step only after verifying the fix. Then end with status FIXED_AFTER_FAILURE so the gate loops back to deploy-stormwind and repeats the fleet from the top.
7. If the switch is clean, verify the whole non-skipped fleet's web health before advancing:
   - First run tailscale status locally; if local tailscale is stopped, bring it up before probing.
   - Read endpoint expectations from ${HOST_MAPPING}.
   - Probe every endpoint for every non-skipped host, not just ${host}.
   - Use the documented expected status, defaulting to final 2xx after redirects.
8. If any endpoint is unhealthy, heal the root cause before advancing. Allow up to 3 heal rounds. If you fix anything, end with FIXED_AFTER_FAILURE so the workflow restarts at deploy-stormwind even if a restart was not strictly required.
9. If a heal/config fix needs another apply, verify with colmena build --on <owning-host> --impure, but let this workflow's deploy sequence perform applies in order.
10. Do not fake success: no fake 200s, no removed checks, no disabled services just to pass.

End your final line with exactly one status token and a concise summary:
- CLEAN_DEPLOYED: ${host} switched cleanly and all non-skipped fleet endpoints are healthy.
- SKIPPED_UNREACHABLE: ${host} was unreachable and was recorded in ${STATE_FILE}; continue without it.
- FIXED_AFTER_FAILURE: a deploy/build/activation/health failure was fixed or repo/remote state changed; the workflow must loop to deploy-stormwind.
- ABORTED: manual intervention is required.
`,
		checks: [
			{
				type: "agent",
				id: `${host}-not-aborted`,
				name: `${host} did not abort`,
				prompt:
					"Pass if the deploy step ended as CLEAN_DEPLOYED, SKIPPED_UNREACHABLE, or FIXED_AFTER_FAILURE. Fail only if it ended as ABORTED, requested manual intervention, exceeded its heal attempts, or left the situation unresolved.",
				onFail: "stop",
			},
			{
				type: "agent",
				id: `${host}-clean-deploy`,
				name: "Host deployed cleanly or was skipped unreachable",
				prompt:
					"Pass only if this host step ended as CLEAN_DEPLOYED with all non-skipped fleet endpoints healthy, or SKIPPED_UNREACHABLE with the host recorded as skipped. Fail if the step ended as FIXED_AFTER_FAILURE, changed Nix repository files, fixed remote state, healed an unhealthy endpoint, or otherwise encountered any failure that was repaired. A failure here intentionally loops the workflow back to deploy-stormwind so the whole fleet is redeployed from the top.",
				onFail: {
					goto: "deploy-stormwind",
					maxLoops: 3,
					onExhausted: "stop",
					feedback: true,
				},
			},
		],
	};
}

export default {
	name: "mass-deploy",
	description:
		"Sequentially deploy the NixOS fleet with pre-flight checks, workaround hygiene, per-host switches, and fleet-wide web health gates.",
	defaults: {
		delegation: "auto",
		onFail: "stop",
		maxLoops: 3,
	},
	steps: [
		{
			id: "pre-flight",
			title: "Pre-flight repository and host checks",
			prompt: `Prepare a full-fleet remote NixOS deployment from ${REPO}.

Read ${INFRA_SKILL} first and follow its full-fleet deployment contract. Do not deploy yet.

Initialize ${STATE_FILE} as JSON with at least:
{
  "skippedHosts": [],
  "events": []
}

Perform these pre-flight checks and summarize the result:
1. Run git -C ${REPO} status --porcelain and identify any untracked *.nix files. These are blockers because git+file flakes cannot see them.
2. Confirm colmena is available with colmena --version.
3. SSH reachability check each host in canonical order: ${ORDER_LABEL}. ${SSH_ALIAS_GUIDANCE} Use a short timeout and BatchMode, for example \`ssh -o BatchMode=yes -o ConnectTimeout=10 <host-alias> 'true'\`.
4. Treat unreachable machines as skipped, not blockers. Add them to ${STATE_FILE}. Note that anton may simply be asleep/off.
5. If every host is unreachable, stop and report that there is nothing to deploy.

End with a concise pre-flight summary containing: blockers, skipped/unreachable hosts, reachable hosts, and whether the workflow may continue.`,
			checks: [
				{
					type: "deterministic",
					id: "colmena-available",
					name: "Colmena is available",
					command: "command -v colmena >/dev/null && colmena --version >/dev/null",
					cwd: REPO,
				},
				{
					type: "deterministic",
					id: "no-untracked-nix",
					name: "No untracked Nix files",
					command:
						"test -z \"$(git status --porcelain -- '*.nix' | awk '$1 == \"??\" { print }')\"",
					cwd: REPO,
				},
				{
					type: "deterministic",
					id: "state-file-created",
					name: "Deployment state file initialized",
					command: `node -e 'const fs=require("fs"); const s=JSON.parse(fs.readFileSync(${JSON.stringify(STATE_FILE)}, "utf8")); if (!Array.isArray(s.skippedHosts)) process.exit(1);'`,
				},
				{
					type: "agent",
					id: "preflight-may-continue",
					name: "Pre-flight may continue",
					prompt:
						"Pass if there are no blockers and at least one fleet host is reachable. Unreachable hosts are fine if they were recorded as skipped. Fail if every host is unreachable, colmena is unavailable, untracked *.nix files are present, or any other blocker remains.",
					onFail: "stop",
				},
			],
		},
		{
			id: "workaround-audit",
			title: "Audit temporary nixpkgs workarounds",
			prompt: `Run the advisory Workaround Hygiene phase before deployment.

Use the procedure in ${INFRA_SKILL}. In short:
1. grep -rn 'WORKAROUND(' ${REPO} --exclude-dir=.git.
2. For markers under overlays/, test the stock package at the pinned nixpkgs-unstable rev on a reachable unstable x86_64-linux host, preferring gnomeregan then anton. Use the ~/.ssh/config aliases (\`ssh gnomeregan\`, then \`ssh anton\`) for reachability/build commands. If a host is listed in ${STATE_FILE}'s skippedHosts, do not use it as the builder.
3. If the stock package builds or substitutes cleanly, remove the stale workaround and its marker, update overlays/default.nix if needed, git rm deleted overlay files, and verify the consuming config still evaluates/builds.
4. If the stock build still fails, keep the workaround.
5. For markers outside overlays/, report them as manual and do not modify them.
6. This audit is advisory: when in doubt, keep the override and continue.

Do not deploy hosts in this step. End with a concise audit summary listing each marker as removed, kept, manual, or skipped.`,
			checks: [
				{
					type: "agent",
					id: "audit-summary",
					name: "Audit summary present",
					prompt:
						"Pass if the step either reports no WORKAROUND markers, reports each marker with a removed/kept/manual verdict, or clearly explains that the audit was skipped because no unstable builder was reachable. Fail if it ignored the audit procedure or removed untagged intentional pins.",
				},
			],
		},
		deployStep(
			"stormwind",
			"Deploy stormwind",
			"stormwind is a Hetzner dedicated box. Use the ssh alias `stormwind`; ~/.ssh/config supplies root and port 2222. Runs traceway and gatus; traceway pulls from gitea's registry on orgrimmar.",
		),
		deployStep(
			"ironforge",
			"Deploy ironforge",
			"ironforge is a Hetzner dedicated box. Use the ssh alias `ironforge`; ~/.ssh/config supplies root and port 2222. Heavy podman media stack; activation can take a while when many containers restart.",
		),
		deployStep(
			"orgrimmar",
			"Deploy orgrimmar",
			"orgrimmar is a Hetzner dedicated box. Use the ssh alias `orgrimmar`; ~/.ssh/config supplies root and port 2222. It runs gitea, woodpecker, paperless, calibre-web, filebrowser, and resume.",
		),
		deployStep(
			"anton",
			"Deploy anton",
			"anton is WSL NixOS on a Windows laptop. Use the ssh alias `anton`; ~/.ssh/config supplies the nixos user. It is often asleep/off; exit code 4 can be a spurious dbus-broker reload timeout, so verify the active generation.",
		),
		deployStep(
			"gnomeregan",
			"Deploy gnomeregan",
			"gnomeregan is a home LAN Wi-Fi host. Use the ssh alias `gnomeregan`; ~/.ssh/config supplies the fdrake user. It tracks nixpkgs-unstable and runs the full workstation home-manager stack; read references/gnomeregan.md before changing its config.",
		),
		deployStep(
			"headscale",
			"Deploy headscale/gateway",
			"headscale/gateway is a Hetzner VPS. Use the ssh alias `headscale`; ~/.ssh/config supplies 10.1.1.2 and root. It is the tailscale subnet router for 10.1.0.0/16; keep nginx, /health, and the tailscale client healthy.",
		),
		{
			id: "report",
			title: "Report deployment outcome",
			runInMain: true,
			prompt: `Give the user the final mass-deploy result in plain language.

Read ${STATE_FILE} if present.

Include:
- Overall status.
- Hosts deployed in order.
- Hosts skipped as unreachable and confirmation that they were ignored for the rest of the workflow.
- Any workarounds retired or kept.
- Any failures encountered and what fixed them.
- How many times the workflow looped back to deploy-stormwind because a host required repair.
- Final web-health verification summary for all non-skipped hosts.
- If the run failed or aborted, the exact point of failure and next manual action.

Keep the report concise but include the timeline details needed to audit what happened.`,
		},
	],
};
