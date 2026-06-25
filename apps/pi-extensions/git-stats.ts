/**
 * git-stats — pi footer extension
 *
 * Shows uncommitted git diff stats in the footer status bar alongside pi's
 * default stats (tokens, cost, context %). Updates on session start and after
 * each agent turn.
 *
 * Example output added to footer:  ±3 +45 -12
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

interface GitStats {
  files: string;
  adds: string | null;
  dels: string | null;
}

async function getGitStats(): Promise<GitStats | null> {
  try {
    // Compares working tree + index against HEAD; covers staged and unstaged changes.
    // Returns empty string when tree is clean or we're outside a git repo.
    const { stdout } = await execAsync("git diff --shortstat HEAD 2>/dev/null", {
      timeout: 3000,
    });
    const raw = stdout.trim();
    if (!raw) return null;

    // Format: " 3 files changed, 45 insertions(+), 12 deletions(-)"
    const filesMatch = raw.match(/(\d+) files? changed/);
    const addMatch = raw.match(/(\d+) insertion/);
    const delMatch = raw.match(/(\d+) deletion/);
    if (!filesMatch) return null;

    return {
      files: filesMatch[1]!,
      adds: addMatch?.[1] ?? null,
      dels: delMatch?.[1] ?? null,
    };
  } catch {
    return null;
  }
}

async function updateStatus(ctx: ExtensionContext): Promise<void> {
  const stats = await getGitStats();
  if (!stats) {
    ctx.ui.setStatus("git-stats", undefined);
    return;
  }

  const theme = ctx.ui.theme;
  const parts: string[] = [theme.fg("dim", `±${stats.files}`)];
  if (stats.adds) parts.push(theme.fg("toolDiffAdded", `+${stats.adds}`));
  if (stats.dels) parts.push(theme.fg("toolDiffRemoved", `-${stats.dels}`));

  ctx.ui.setStatus("git-stats", parts.join(" "));
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    await updateStatus(ctx);
  });

  pi.on("turn_end", async (_event, ctx) => {
    await updateStatus(ctx);
  });
}
