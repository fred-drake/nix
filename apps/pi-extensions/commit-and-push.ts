/**
 * commit-and-push — pi command extension
 *
 * Registers /commit-and-push. Switches to openai-codex/gpt-5.6-luna, sends a short
 * "commit everything and push" prompt, then restores the previous model when
 * the agent turn ends.
 *
 * Usage:
 *   /commit-and-push
 */

import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const MODEL_ID = "gpt-5.6-luna";
const PROMPT = "commit everything and push";

export default function (pi: ExtensionAPI) {
  let previousModel: Model<Api> | undefined;
  let restoring = false;

  async function restorePreviousModel(ctx: ExtensionContext): Promise<void> {
    if (!previousModel || restoring) return;
    restoring = true;
    try {
      await pi.setModel(previousModel);
    } catch (err) {
      ctx.ui.notify(
        `Failed to restore previous model: ${err instanceof Error ? err.message : String(err)}`,
        "warning",
      );
    } finally {
      previousModel = undefined;
      restoring = false;
    }
  }

  pi.on("agent_end", async (_event, ctx) => {
    await restorePreviousModel(ctx);
  });

  pi.registerCommand("commit-and-push", {
    description: "Commit everything and push (via openai-codex/gpt-5.6-luna)",
    handler: async (_args, ctx) => {
      if (!ctx.isIdle()) {
        ctx.ui.notify("Agent is busy; try again when idle.", "warning");
        return;
      }

      const model = ctx.modelRegistry.find(PROVIDER, MODEL_ID);
      if (!model) {
        ctx.ui.notify(
          `Model ${PROVIDER}/${MODEL_ID} not found. Is it configured in models.json?`,
          "error",
        );
        return;
      }

      previousModel = ctx.model;

      const current = ctx.model;
      const alreadyOnTarget =
        current?.provider === PROVIDER && current?.id === MODEL_ID;

      if (!alreadyOnTarget) {
        const ok = await pi.setModel(model);
        if (!ok) {
          previousModel = undefined;
          ctx.ui.notify(
            `No API key / connection for ${PROVIDER}/${MODEL_ID}`,
            "error",
          );
          return;
        }
      } else {
        // Already on the target model — nothing to restore.
        previousModel = undefined;
      }

      pi.sendUserMessage(PROMPT);
    },
  });
}
