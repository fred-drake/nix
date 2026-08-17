const REPO = "/Users/fdrake/nix";
const MODEL = "openai-codex/gpt-5.6-sol";
const LOOP_POLICY = {
	maxLoops: 100,
	onExhausted: "stop",
	feedback: true,
};

export default {
	name: "local-deploy",
	description: "Update dependencies and switch the local Nix configuration with repair and review gates.",
	steps: [
		{
			id: "update-all",
			title: "Update all dependencies",
			model: MODEL,
			thinkingLevel: "high",
			prompt: `Make \`just update-all\` succeed from ${REPO}.

The main harness must not directly run any command, investigation, or repair invocation. Delegate every command execution, investigation, diagnosis, edit, repair, and retry to subagents using \`${MODEL}\` with high reasoning. This includes the initial \`just update-all\` attempt and every attempt made while diagnosing or verifying a failure.

If \`just update-all\` fails, use those subagents to diagnose and fix the root cause in the Nix configuration, then retry until it succeeds. Do not mask failures or weaken checks.

After every code or configuration change made during repair, and before the next \`just update-all\` retry, delegate a fresh adversarial reviewer subagent using \`${MODEL}\` with high reasoning to review that change. Address every reviewer finding before retrying. If addressing a finding changes code or configuration, obtain another fresh adversarial review before the retry. This per-change review is mandatory and is separate from the final agent gate.`,
			checks: [
				{
					type: "deterministic",
					id: "update-all-command",
					name: "just update-all succeeds",
					command: "just update-all",
					cwd: REPO,
					timeoutMs: 900000,
					onFail: { goto: "update-all", ...LOOP_POLICY },
				},
				{
					type: "agent",
					id: "update-all-final-review",
					name: "Adversarial update review",
					prompt: `Delegate a fresh adversarial reviewer subagent using \`${MODEL}\` with high reasoning. Require it to independently review all final code and configuration changes relevant to \`just update-all\` and confirm that the latest deterministic \`just update-all\` check succeeded without masked failures or weakened checks. This final gate is additional to, and does not replace, the fresh review required after every repair change.

After considering the review, explicitly call \`anvil_verdict\` using the exact runtime \`check_id\` supplied by Anvil in the check instruction. Pass only if the reviewer confirms both the final relevant changes and the successful command result; otherwise fail and report the findings for the retry loop.`,
					onFail: { goto: "update-all", ...LOOP_POLICY },
				},
			],
		},
		{
			id: "switch",
			title: "Switch local configuration",
			model: MODEL,
			thinkingLevel: "high",
			prompt: `Make \`just switch\` succeed on this machine from ${REPO}.

The main harness must not directly run any command, investigation, or repair invocation. Delegate every command execution, investigation, diagnosis, edit, repair, and retry to subagents using \`${MODEL}\` with high reasoning. This includes the initial \`just switch\` attempt and every attempt made while diagnosing or verifying a failure.

If \`just switch\` fails, use those subagents to diagnose and fix the root cause in the Nix configuration, then retry until it succeeds. Do not mask failures or weaken checks.

After every code or configuration change made during repair, and before the next \`just switch\` retry, delegate a fresh adversarial reviewer subagent using \`${MODEL}\` with high reasoning to review that change. Address every reviewer finding before retrying. If addressing a finding changes code or configuration, obtain another fresh adversarial review before the retry. This per-change review is mandatory and is separate from the final agent gate.`,
			checks: [
				{
					type: "deterministic",
					id: "switch-command",
					name: "just switch succeeds",
					command: "just switch",
					cwd: REPO,
					onFail: { goto: "switch", ...LOOP_POLICY },
				},
				{
					type: "agent",
					id: "switch-final-review",
					name: "Adversarial switch review",
					prompt: `Delegate a fresh adversarial reviewer subagent using \`${MODEL}\` with high reasoning. Require it to independently review all final code and configuration changes relevant to \`just switch\` and confirm that the latest deterministic \`just switch\` check succeeded on this machine without masked failures or weakened checks. This final gate is additional to, and does not replace, the fresh review required after every repair change.

After considering the review, explicitly call \`anvil_verdict\` using the exact runtime \`check_id\` supplied by Anvil in the check instruction. Pass only if the reviewer confirms both the final relevant changes and the successful command result; otherwise fail and report the findings for the retry loop.`,
					onFail: { goto: "switch", ...LOOP_POLICY },
				},
			],
		},
	],
};
