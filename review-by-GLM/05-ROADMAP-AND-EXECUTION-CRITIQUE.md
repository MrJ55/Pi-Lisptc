# Review-by-GLM5p3 — Roadmap and Execution Critique

Phase-by-phase analysis with revised recommendations.

---

## Overall Assessment

The phase ordering (0→1→2→3→4→5→6→7→8→9-12) is logically sound. Each phase builds on the previous. The core/additive split is well-maintained. However, several phases have gaps in their task lists, and one critical architectural change (prompt cache separation) is missing from the roadmap entirely.

---

## Phase 0: Baseline & Profiles

### Verdict: Adequate but incomplete

**What's Good:**
- Pin upstream SHAs (T0.1) is correctly the first task
- Two launch scripts provide immediate testability

**What's Missing:**
- **No task for verifying Pi's `buildSystemPrompt` contract.** The entire project depends on this API behaving as assumed. T0.1 should include: read Pi's `system-prompt.ts` source, document the exact behavior of `customPrompt`, verify project context is still appended.
- **No task for initializing the Node.js project.** `package.json`, `tsconfig.json`, dependencies — none exist. Add T0.2a: `pnpm init`, configure TypeScript, add pi-lisptc dependencies.
- **No task for setting up CI.** Even a basic `npm test` in GitHub Actions would catch regressions.
- **No task for setting up the extension development workflow.** How does the developer test changes to the Pi extension? Hot reload? Restart?

**Revised Task List:**
- T0.1: Clone upstream, record SHAs, **verify buildSystemPrompt contract**
- T0.2: **Initialize Node.js project** (package.json, tsconfig, dependencies)
- T0.3: Scaffold extension package (as planned)
- T0.4: Scripts (as planned)
- T0.5: **Set up basic CI** (typecheck + lint)
- T0.6: README profile section
- T0.7: Verification (as planned)

---

## Phase 1: Prompt Assembly

### Verdict: architecturally flawed without cache separation

**What's Good:**
- The three-part merge formula is clear
- Interpreter source import strategy is defined

**What's Wrong:**
- **The merged prompt puts volatile mind state in the cache-breaking prefix.** This is not a Phase 8 optimization problem — it's a Phase 1 architecture problem. Building the prompt wrong first and fixing it later means retesting every subsequent phase.
- **No task for creating `INTERPRETER_SOURCE_LLM`.** The plan includes all 11 source files, wasting ~2-3k tokens/turn on irrelevant code.
- **No task for measuring token cost.** How many tokens does the merged prompt consume? What's the remaining context for conversation? These numbers inform every subsequent design decision.

**Revised Task List:**
- T1.1: Extract Pi coding core (as planned)
- T1.2: Lisptc channel rules (as planned)
- T1.3: **Create `INTERPRETER_SOURCE_LLM`** — exclude mcp-broker.ts, mcp-oauth.ts, jobs-broker.ts, jobs-protocol.ts
- T1.4: **Implement prompt layer separation** — Layer 0 (stable system prompt) vs Layer 2 (volatile, trailing message)
- T1.5: before_agent_start integration (as planned)
- T1.6: setActiveTools([]) (as planned)
- T1.7: **Measure token cost** — log total system prompt tokens, project context tokens, remaining budget
- T1.8: Verification (as planned, but include cache hit measurement)

---

## Phase 2: Image Safety

### Verdict: Addresses the wrong half of the problem

**What's Good:**
- Pre-eval validation (stripFences → parse → validate) is correct
- Retry with error feedback is the right mechanism

**What's Wrong:**
- **The plan does NOT fix the upstream `repl.reset()` on runtime error.** This is the more dangerous failure mode. A validated form can still fail at runtime (MCP timeout, division by zero, wrong argument count). When this happens, lisptc resets the entire interpreter.
- **Retry budget (2-3) may be insufficient.** No analysis of typical failure rates per provider.

**Revised Task List:**
- T2.1: stripFences + validateForm (as planned)
- T2.2: message_end pipeline (as planned)
- **T2.3: Fix upstream error recovery** — patch or wrap AgentRepl to preserve definitions on runtime error
- T2.4: Soften reset-on-throw (as planned, but now secondary to T2.3)
- T2.5: **Configurable retry budget** — default 3, provider-specific overrides
- T2.6: Verification (as planned)

---

## Phase 3: Provider Widening

### Verdict: Underspecified

**What's Good:**
- Capability registry concept is right

**What's Wrong:**
- **No `tool-call` mode implementation.** This is the most reliable mode for OpenAI/Anthropic. Its absence means these providers fall back to the weakest mode (retry).
- **Provider registry is trivial** — hardcoded object with no discovery mechanism.
- **No cache composition specification** — how do prompt_cache_key and grammar interact?

**Revised Task List:**
- T3.1: Capability registry (as planned, but extensible)
- T3.2: Conditional grammar (as planned)
- **T3.3: Implement `tool-call` mode** — single `eval_lisp_form` tool, forced tool_choice
- T3.4: **Per-provider retry feedback templates**
- T3.5: Cache composition testing (as planned, but test interaction with grammar)
- T3.6: Verification on three providers: Fireworks (grammar), OpenAI/Anthropic (tool-call), one fallback (retry)

---

## Phase 4: MCP Bootstrap

### Verdict: Adequate

**What's Good:**
- Lazy loading consideration
- Outer tools stay empty

**What's Missing:**
- **No Vestige adapter abstraction** — Phase 7 depends on Vestige MCP, but its API is unstable. Phase 4 should define the adapter interface.
- **No MCP health check.** If a server fails during bootstrap, what happens?

**Revised Task List:**
- T4.1: Config file (as planned)
- T4.2: Auto-load on session_start (as planned)
- **T4.3: Define Vestige adapter interface** (src/host/vestige-adapter.ts)
- T4.4: MCP health check on bootstrap
- T4.5: Verification (as planned)

---

## Phase 5: User Channel

### Verdict: Adequate

**What's Good:**
- `(reply)` / `(halt)` is a clean interface
- Pretty-printer for structured values

**What's Missing:**
- **No error display format.** When eval fails, what does the user see?
- **No progress indication** for long MCP operations.

**Revised Task List:**
- T5.1: Detect reply/halt (as planned)
- T5.2: Pretty-printer (as planned)
- **T5.3: Error display format** — structured, not raw stack traces
- T5.4: Prompt update (as planned)
- T5.5: Verification (as planned)

---

## Phase 6: Persistence

### Verdict: Well-designed, one concern

**What's Good:**
- mind-api.lisp namespace is clean
- Caps (40 pins, 30 skills) are reasonable
- Disk prefs save/load is practical

**Concern:**
- **`mind/reify!` replaces `*mind/retrieved*`** but the plan also says "merge-prefs" in the reify call. This is two different operations (replace vs merge) in the same function. The implementation must clearly separate them.

---

## Phase 7: Vestige Reify Loop

### Verdict: Most complex phase, needs more specification

**What's Good:**
- Auto-recall on user message is the right trigger
- Gated ingest (3/turn max) prevents spam
- Failure modes are acknowledged

**What's Missing:**
- **No recall quality threshold.** Garbage in, garbage out.
- **No ingest failure handling.** If smart_ingest fails, is the note lost?
- **No specification of Vestige query format.** What does the recall MCP tool expect as input?
- **Bootstrap recall query is hardcoded.** `"preferences project invariants skills " + projectName` — what if the project has no memories yet?

**Revised Task List:**
- T7.1: **Implement Vestige adapter** with retry, fallback, degradation detection
- T7.2: Recall trigger with quality threshold
- T7.3: mind/note! with ingest failure queue
- T7.4: Bootstrap recall (as planned, but handle empty results)
- T7.5: **Deliver mind_active as Layer 2 (trailing message), not in system prompt**
- T7.6: Verification with logged recall quality metrics

---

## Phase 8: Optional Harden

### Verdict: Correctly deprioritized, but one item should be promoted

**L0/L1 prompt split** is the most impactful optimization. However, if Phase 1 implements the prompt layer separation (as recommended), L0/L1 becomes a refinement of the existing architecture rather than a new concept.

**Sandbox eval** should be promoted from "optional" to "recommended." Without it, any successful eval that defines a function with a side effect (e.g., infinite loop, file deletion) is committed to the mind permanently.

---

## Phases 9-12: Additive Track

### Verdict: Well-scoped, but entry criteria are too vague

The plan says "after phases 0-7 daily-stable" and "after documented failure" but doesn't define what "daily-stable" means quantitatively.

**Proposed Entry Criteria:**
- Phases 0-7 pass all verification checkboxes
- Prompt cache hit rate > 80% on turns 3+
- Retry rate < 5% on grammar-constrained providers
- Recall latency p99 < 200ms
- Zero session crashes from mind state corruption in 50+ turn sessions
- At least 3 different users have used lisp-mind profile for real work for 1+ week each

---

## Missing Phase: Phase -1 (Pre-Work)

The following should happen before Phase 0:

1. **Pin upstream SHAs** — Already in Phase 0 T0.1, but should be the absolute first action
2. **Read Pi's `buildSystemPrompt` source** — Verify the customPrompt contract
3. **Read lisptc's `source.ts`** — Measure token cost of INTERPRETER_SOURCE
4. **Spike: Vestige MCP tool discovery** — Call `list-tools` on a running Vestige instance, document the exact tool names and schemas
5. **Spike: Prompt layer separation** — Test whether Pi supports trailing developer messages
6. **Set up project scaffolding** — package.json, tsconfig, CI
7. **Decide on test framework** — Vitest (consistent with lisptc) recommended

---

## Revised Phase Ordering

```
Phase -1: Pre-work (SHAs, API verification, spikes, scaffolding)
Phase  0: Baseline & profiles (as planned, with CI)
Phase  1: Prompt assembly + CACHE SEPARATION + source optimization
Phase  2: Image safety + ERROR RECOVERY FIX
Phase  3: Provider widening (grammar + tool-call + retry)
Phase  4: MCP bootstrap + Vestige adapter interface
Phase  5: User channel
Phase  6: Persistence (mind-api.lisp, prelude, pins)
Phase  7: Vestige reify loop + Layer 2 injection
Phase  8: Harden (sandbox promoted to recommended)
--- gate: quantitative exit criteria ---
Phase  9: Context contributors (refactor Phase 7 recall)
Phase 10: Bounded RLM (after documented failure)
Phase 11: Agenda + papercuts
Phase 12: Soft generations + skills
```

The only structural change is: (a) adding Phase -1, (b) merging cache separation into Phase 1, (c) merging error recovery into Phase 2, (d) adding tool-call mode to Phase 3, (e) adding Vestige adapter to Phase 4.
