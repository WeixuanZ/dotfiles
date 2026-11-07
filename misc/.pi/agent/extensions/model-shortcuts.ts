import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// /gemini and /opus switch the live session. The first installed provider
// that actually has the model wins, so a subscription login is preferred
// over an API-key provider of the same id.

type ModelRef = { provider: string; id: string };

async function useFirst(
  pi: ExtensionAPI,
  ctx: { modelRegistry: { find: (provider: string, id: string) => unknown }; ui: { notify: (message: string, level: "info" | "error") => void } },
  label: string,
  candidates: ModelRef[],
  loginHint: string,
) {
  for (const candidate of candidates) {
    let model: unknown;
    try {
      model = ctx.modelRegistry.find(candidate.provider, candidate.id);
    } catch {
      model = undefined;
    }
    if (!model) continue;
    try {
      const ok = await pi.setModel(model as never);
      if (ok === false) continue;
    } catch {
      continue;
    }
    ctx.ui.notify(`${label}: ${candidate.provider}/${candidate.id}`, "info");
    return;
  }
  ctx.ui.notify(`No ${label} model is available. ${loginHint}`, "error");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("gemini", {
    description: "Switch to Gemini 4 (Google AI Pro via Antigravity)",
    handler: async (_args, ctx) => {
      await useFirst(
        pi,
        ctx,
        "Gemini 4",
        [
          { provider: "antigravity", id: "gemini-4-argon" },
          { provider: "antigravity", id: "gemini-4-argon-high" },
          { provider: "google", id: "gemini-4-argon" },
        ],
        "Log in with /login antigravity. Do not set GEMINI_API_KEY if you want the Pro plan.",
      );
    },
  });

  pi.registerCommand("opus", {
    description: "Switch to Claude Opus 5.5 on the Claude subscription",
    handler: async (_args, ctx) => {
      await useFirst(
        pi,
        ctx,
        "Opus 5.5",
        [
          { provider: "claude-sdk", id: "claude-opus-5-5" },
          { provider: "claude-subscription", id: "claude-opus-5-5" },
        ],
        "Log in once with `claude`, then restart pi. Do not export ANTHROPIC_API_KEY.",
      );
    },
  });
}
