/**
 * ornith-local — pi provider extension
 *
 * Registers Ornith-1.0-35B-8bit (mlx-community) as a local provider when
 * served via mlx-vlm on http://localhost:8080.
 *
 * Start the server first:
 *   model-ornith-1-0-35b-8bit
 *   (abbr for: uvx --from mlx-vlm mlx_vlm.server --model mlx-community/Ornith-1.0-35B-8bit --port 8080)
 *
 * Then switch to it in pi with:
 *   /model ornith-local/mlx-community/Ornith-1.0-35B-8bit
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerProvider("ornith-local", {
    name: "Ornith Local (MLX)",
    baseUrl: "http://localhost:8080/v1",
    apiKey: "not-needed",
    api: "openai-completions",
    models: [
      {
        id: "mlx-community/Ornith-1.0-35B-8bit",
        name: "Ornith 1.0 35B (8-bit MLX)",
        // Ornith is a Qwen 3.5-based reasoning model — it emits <think>…</think>
        // blocks natively. thinkingFormat: "qwen" sends enable_thinking to the
        // mlx-vlm server so pi can toggle thinking on/off via /thinking.
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 262144,
        maxTokens: 16384,
        compat: {
          supportsDeveloperRole: false,
          maxTokensField: "max_tokens",
          thinkingFormat: "qwen",
        },
      },
    ],
  });
}
