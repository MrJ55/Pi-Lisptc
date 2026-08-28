# Review-by-GLM5p3 — ADR Critique

ADR-by-ADR analysis with proposed amendments.

---

## ADR-0001: Merge Prompt, Not Replace
**Status:** Accepted | **Verdict:** Correct decision, underspecified execution

### What's Right
The identification that stock lisptc's `before_agent_start` returns `{ systemPrompt: SYSTEM_PROMPT }` which **replaces** Pi's entire system prompt is the single most important finding in the project. Without this ADR, Pi-Lisptc would ship with zero coding guidelines, no AGENTS.md context, and no cwd awareness.

### What's Missing
1. **No specification of what "Pi coding core" means concretely.** The plan (Phase 1, T1.1) says "extract Pi coding core string" but doesn't define which sections of Pi's prompt to keep. Pi's `buildSystemPrompt` likely includes: role description, tool descriptions, concise/path guidelines, Pi docs index, and project context attachments. Which of these survive the merge?

2. **No analysis of `buildSystemPrompt`'s actual behavior.** The ADR assumes `buildSystemPrompt` still appends project context when `customPrompt` is set. This must be verified against Pi's source code. If Pi's implementation prepends customPrompt but then overwrites it, the merge fails.

3. **No mention of the `SYSTEM_PROMPT`/`INTERPRETER_SOURCE` disconnect.** lisptc's `system-prompt.ts` imports `INTERPRETER_SOURCE` but does NOT include it in the exported `SYSTEM_PROMPT`. The ADR's merge formula assumes the source is already present. Pi-Lisptc must concatenate it explicitly.

### Proposed Amendment
Add to ADR-0001 Consequences:
- "Pi-Lisptc must verify that `buildSystemPrompt` preserves project context attachments when `customPrompt` is set, by reading Pi's source at the pinned SHA."
- "Pi-Lisptc must concatenate `INTERPRETER_SOURCE` explicitly in its own prompt assembly, as lisptc's stock `SYSTEM_PROMPT` export does not include it."
- "Pi-Lisptc must document which sections of Pi's default prompt are retained, modified, or removed."

---

## ADR-0002: Vestige Cabinet, lisptc Cortex
**Status:** Accepted | **Verdict:** Sound conceptual model, missing failure modes

### What's Right
The cabinet/cortex distinction is a genuine contribution to agent architecture thinking. Vestige as durable, recallable, append-only store vs. the REPL as live, ephemeral, executable state is the right decomposition. The bridge (recall → reify → act → ingest) is well-defined.

### What's Missing
1. **No degradation strategy.** The plan handles Vestige being "down" (empty hits, warn once) but not degraded (slow, returning low-quality results, partial data). A degraded Vestige is worse than a down Vestige because the agent acts on bad recall.

2. **No write-path reliability.** `smart_ingest` is "gated" but the gate mechanism is undefined. If ingest fails, does the agent retry? Queue? Forget? The epilogue functions (`mind/note!`, `mind/prefer!`, `mind/fail!`) must have defined semantics on ingest failure.

3. **No memory consistency model.** If the agent reads a memory, acts on it, and the memory is then updated by a concurrent session (if shared Vestige), the agent's action may be based on stale data. The plan doesn't address this.

### Proposed Amendment
Add to ADR-0002:
- "Define a recall quality threshold: if the best hit's relevance score is below threshold, skip reification and log."
- "Define ingest failure semantics: queue with max depth N, replay on next turn, drop oldest on overflow."
- "Document that Vestige is assumed single-session for v1. Multi-session consistency is a non-goal."

---

## ADR-0003: Validate Before Eval
**Status:** Accepted | **Verdict:** Correct, but conflicts with upstream error recovery

### What's Right
Parse-before-eval is non-negotiable. Without it, any malformed output corrupts the REPL. The retry mechanism (2-3 attempts with error feedback) is the right approach.

### Critical Conflict
lisptc's upstream `lisp-repl.ts` catches ALL exceptions from `eval` and calls `repl.reset()`. This means even after successful validation, a runtime error (e.g., MCP tool failure, division by zero) will destroy the mind.

The ADR addresses pre-eval validation but not post-eval error recovery. These are different problems:
- **Pre-eval validation** prevents malformed code from reaching the interpreter (ADR-0003)
- **Post-eval error recovery** preserves definitions when valid code fails at runtime (not addressed)

### Proposed Amendment
Split ADR-0003 or create ADR-0010:
- "On runtime error (EvalException): report error to model, preserve all definitions, do NOT reset."
- "On catastrophic error (interpreter state corruption): reset, log, attempt prelude reload."
- "Define 'catastrophic' as: nil pointer in interpreter internals, not application-level errors."

---

## ADR-0004: Reify Replace, Not Accumulate
**Status:** Accepted | **Verdict:** Excellent, one edge case

### What's Right
This prevents the most common agent memory failure mode: unbounded context growth from accumulating recall results. The `setq` replace discipline is simple and correct.

### Edge Case
The plan defines `*mind/retrieved*` as replaced each turn. But `*mind/pins*` is a "capped ring." If a pin is demoted in one turn and the same fact is recalled in the next turn, there's a race between the pin ring and the retrieval replacement. The plan doesn't specify priority.

### Proposed Amendment
- "`*mind/retrieved*` takes precedence over pin ring entries with overlapping content. Deduplication happens during reify."

---

## ADR-0005: Provider Modes
**Status:** Accepted | **Verdict:** Right approach, underspecified

### What's Right
Three modes (grammar, tool-call, retry) cover the provider landscape. The explicit decision to make retry a first-class path (not a fallback) is correct — for many providers, retry with validation IS the constraint mechanism.

### What's Missing
1. **No `tool-call` mode specification.** For OpenAI/Anthropic/Gemini, the most reliable constrained output mechanism is forced tool calling with a single `eval_lisp_form` tool. The ADR mentions this implicitly ("strict-tool") but doesn't define the tool schema or the extraction logic.

2. **No provider-specific tuning.** Different models have different failure modes. Claude tends to over-explain in tool calls. GPT tends to add prose before JSON. The retry feedback should be provider-specific.

3. **Cache composition is mentioned but not specified.** The ADR says "cache first on wire" but doesn't define how `opencode-go-cache`'s `prompt_cache_key` and Pi-Lisptc's grammar constraint interact. Does the cache key include the grammar? If so, changing the grammar busts cache.

### Proposed Amendment
- "Define `tool-call` mode: single tool `eval_lisp_form` with `{ form: string }`, `tool_choice: forced`. Extract `form` from tool call argument."
- "Per-provider retry feedback templates: 'Output only valid lisptc forms. No prose, no markdown, no explanations.'"
- "Document cache key composition: prompt_cache_key must not include volatile mind state."

---

## ADR-0006: Profiles (lisp-mind vs pi-default)
**Status:** Accepted | **Verdict:** Sound, missing transition mechanics

### What's Right
Two profiles prevent the worst failure mode: a user who wants classic Pi gets it unmodified. The `setActiveTools([])` in lisp-mind is the key enabler.

### What's Missing
1. **No mid-session switching.** If a user needs to drop into raw Pi for one task, they must restart.
2. **No extension composition rules.** What happens to `opencode-go-cache` in lisp-mind profile? The plan says it's compatible but doesn't specify.
3. **No profile persistence.** Does the user's last profile carry across sessions?

### Proposed Amendment
- "Mid-session profile switching is a non-goal for v1. Document this limitation."
- "`opencode-go-cache` loads in both profiles. In lisp-mind, it injects cache fields but does not add tools."
- "Default profile stored in `.lisptc/config.json`. Override via CLI flag."

---

## ADR-0007: Context Contributors
**Status:** Proposed (post phase 0-8) | **Verdict:** Well-designed, should be promoted to Accepted before Phase 9

### What's Right
This is a direct port of Autolith's context system, and the adaptation is well-done:
- The schema (id, instruction, evidence, priority, lifetime, class) matches Autolith's
- The mandatory vs advisory budget split is preserved
- The lifetime model (`:turn`/`:next-request`/`:while-relevant`) is correct

### Improvement Over Autolith
Autolith uses `:while-relevant` which requires the contributor to re-evaluate each turn. Pi-Lisptc could simplify to just `:turn` and `:next-request` for v1, avoiding the complexity of relevance tracking.

### Proposed Amendment
- "For v1, support only `:turn` and `:next-request` lifetimes. Defer `:while-relevant` to measured need."
- "Set advisory budget to 2,000 tokens (Autolith uses ~1,500 but Pi-Lisptc's mind_active may need more)."
- "Mandatory total cap: 8,000 characters (matching Autolith)."

---

## ADR-0008: Bounded RLM
**Status:** Proposed (phase 10) | **Verdict:** Correctly deferred, one design concern

### What's Right
RLM is correctly identified as high-cost and correctly deferred behind "documented failure" evidence. The budget object (calls, tokens, depth) matches Autolith's design.

### Design Concern
Autolith's RLM uses separate SBCL worker images for isolation. Pi-Lisptc's interpreter runs in-process on the main thread. An RLM sub-call would need to:
1. Create a new `Interp` instance (or reuse with isolated environment)
2. Run the sub-request
3. Return results to the parent

But the parent's `Atomics.wait` blocks the main thread. If RLM also blocks (waiting for the provider), we have nested blocking — potentially deadlocking if the event loop is needed.

### Proposed Amendment
- "RLM sub-requests must use the Pi provider API directly (not through the interpreter's blocking jobs runtime)."
- "Budget enforcement is host-side (TypeScript), not Lisp-side. The Lisp `mind/infer` function is a thin wrapper that calls the host."

---

## ADR-0009: Soft Generations and Structured Surfaces
**Status:** Proposed (phases 11-12) | **Verdict:** Well-scoped, missing crash safety

### What's Right
The explicit rejection of Autolith's private mutation repos and recovery-image boot loops is correct. Pi-Lisptc operates in Node.js where these patterns don't apply. The snapshot/restore approach (save prelude + pins + prefs to file) is appropriate.

### What's Missing
Autolith's crash-safe vault (recovery input vaults that survive crashes) has no equivalent in Pi-Lisptc. If the Node process crashes between `mind/note!` (intent) and `smart_ingest` (persistence), the note is lost.

### Proposed Amendment
- "Phase 12 snapshots are best-effort. Document that crash between note and ingest may lose data."
- "Consider a write-ahead log for mind epilogue operations if crash safety becomes a requirement."

---

## Missing ADRs

### ADR-0010: Error Recovery (NEW)
Define post-eval error recovery semantics:
- Runtime errors preserve definitions
- Only catastrophic interpreter corruption triggers reset
- Error feedback format to the model

### ADR-0011: Prompt Cache Architecture (NEW)
Define the stable/volatile prompt layer separation:
- Layer 0: System prompt (stable)
- Layer 1: Project context (per-workspace)
- Layer 2: Mind state (per-turn, trailing message)
- Never mix volatile state into the cache-breaking prefix

### ADR-0012: Interpreter Source Optimization (NEW)
Define the LLM-relevant source subset:
- Exclude worker-thread implementation files
- Exclude OAuth protocol details
- Create `INTERPRETER_SOURCE_LLM` export
- Measure token savings