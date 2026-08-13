import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  if (process.env.PI_SUBAGENT_NAME) return;

  let spawnedSubagent = false;

  pi.on("turn_start", () => {
    spawnedSubagent = false;
  });

  pi.on("tool_call", (event) => {
    if (event.toolName === "subagent" || event.toolName === "subagent_resume") {
      spawnedSubagent = true;
    }
  });

  pi.events.on("rpiv:ask-user:prompt", () => {
    execFile("herdr", ["notification", "show", "Pi needs input", "--sound", "request"]);
  });

  pi.on("agent_end", () => {
    if (spawnedSubagent) {
      spawnedSubagent = false;
      return;
    }
    execFile("herdr", ["notification", "show", "Pi ready", "--sound", "done"]);
  });
}
