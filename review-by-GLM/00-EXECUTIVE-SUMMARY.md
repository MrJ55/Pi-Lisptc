# Review-by-GLM5p3 — Executive Summary

**Reviewer:** GLM-5p3 (independent audit)
**Date:** 2026-08-28
**Scope:** Full codebase audit of Pi-Lisptc plan, lisptc (1hachem), and autolith (lambda-symbolics)
**Method:** Clone + line-by-line reading of all source files across all three repositories. No prior reviews consulted.

---

## Verdict: Ambitious vision, zero execution, several architectural risks already visible at the planning stage.

Pi-Lisptc sets out to merge three systems — Pi (coding harness), lisptc (Lisp REPL forced-action channel), and Vestige (associative memory) — into a "living mind" that preserves Pi's coding performance while adding persistent, programmatic cognitive state. The vision is coherent and the problem space (coherence failure, filing-cabinet knowledge, context bloat) is real and well-diagnosed. The Autolith-inspired additive track (phases 9-12) shows sophisticated taste in identifying which patterns to port.

However, the repository currently contains **zero runnable code**. Every deliverable is a planning document, a stub, or a commented-out placeholder. This review identifies 23 concrete issues — 6 critical, 10 significant, 7 moderate — that should be addressed before or during implementation. Several of these issues are already traceable to specific lines of upstream code.

---

## Key Findings

### Critical (Blocks Correctness)

| # | Finding | Source | Impact |
|---|---------|--------|--------|
| C1 | **lisptc's `SYSTEM_PROMPT` does not include `INTERPRETER_SOURCE`** — The import exists in `system-prompt.ts` but the exported constant is only `POLICY`. Pi-Lisptc's Phase 1 merge plan assumes the source is already concatenated. | `lisptc/apps/pi/extension/system-prompt.ts` lines 1, 54 | Phase 1 will ship a broken prompt unless this is caught. The LLM will have zero knowledge of the language semantics it's supposed to output. |
| C2 | **`string-trim` bug in lisptc interpreter** — `_whitespace?` helper checks for the literal two-character strings `"\\t"`, `"\\n"`, `"\\r"` instead of actual tab/newline/CR characters. `(string-trim "\thello\t")` silently fails. | `lisptc/packages/interpreter/src/lisp.ts` prelude `string-trim` definition | Any agent-generated code using `string-trim` on tab-containing input will produce wrong results. Subtle data-corruption bug. |
| C3 | **No upstream SHAs pinned** — All entries in `UPSTREAM-PINS.md` are TBD. Pi, lisptc, and Vestige are moving targets. | `Pi-Lisptc/docs/UPSTREAM-PINS.md` | Implementation cannot begin without pinning. Any code written against current APIs may break on next upstream release. |
| C4 | **Interpreter error recovery resets the entire REPL** — `lisp-repl.ts` catches exceptions and calls `repl.reset()`, destroying all definitions. Pi-Lisptc's "living mind" survives only if definitions persist across turns. | `lisptc/apps/pi/extension/lisp-repl.ts` evalCode catch block | A single malformed tool call or MCP failure lobotomizes the agent mid-session. Directly conflicts with G3 (Living Mind). |
| C5 | **`AgentRepl` not available on session server** — The shared-session server (`session-server.ts`) instantiates `MemoryRepl`, not `AgentRepl`. No `halt`, no conversation globals. | `lisptc/packages/repl/src/session-server.ts` | If Pi-Lisptc ever wants multi-client shared state (e.g., IDE + terminal), the session server cannot provide agent features. |
| C6 | **Vestige tool API is unstable and undocumented at the code level** — Pi-Lisptc's Phase 7 depends on calling Vestige recall/smart_ingest via MCP, but the tool names "may vary by version" (per UPSTREAM-PINS.md) and no concrete API contract exists. | `Pi-Lisptc/docs/UPSTREAM-PINS.md` | Phase 7 implementation is blocked until Vestige stabilizes its MCP tool interface or Pi-Lisptc defines an adapter layer. |

### Significant (Affects Architecture)

| # | Finding | Source | Impact |
|---|---------|--------|--------|
| S1 | **Full interpreter source in every prompt turn** — 11 source files (lisp.ts alone is 2386 lines) including irrelevant `mcp-broker.ts` and `mcp-oauth.ts`. No measurement of token cost or cache hit rates. | `lisptc/packages/interpreter/src/source.ts` | Will consume 15-25k+ tokens per turn. Phase 8's L0/L1 split is acknowledged but deferred. Risk: the project may become non-viable on smaller context windows before the optimization ships. |
| S2 | **No prompt cache stability architecture** — Autolith's single highest-impact finding (context-cost-report.org) is separating stable prefix from volatile suffix. Pi-Lisptc's merged prompt mixes stable (Pi coding role) and volatile (mind_active, *mind/retrieved*) in a single `customPrompt`. | `Pi-Lisptc/docs/03-architecture-overview.md`, `autolith/docs/context-cost-report.org` | Every turn that changes recalled memory busts the entire prompt cache from token zero. This is the most expensive architectural oversight in the plan. |
| S3 | **Fireworks lock-in in lisptc extension** — Provider registration, grammar-based structured output, and `thinking`-part filtering are all hardcoded for Fireworks. Pi-Lisptc's G6 (any major provider) requires significant extension surgery. | `lisptc/apps/pi/extension/lisp-repl.ts` registerFireworks, before_provider_request | The capability registry (Phase 3) is too trivial (`{ fireworks: { grammar: true }, default: { grammar: false } }`) to handle the actual complexity of provider-specific behavior. |
| S4 | **Retry budget (2-3) is fragile** — Weak models or complex tasks may consistently exceed this. No exponential backoff, no model-specific tuning. | `Pi-Lisptc/plan/phase-02-image-safety.md` | On non-grammar providers, the retry path is the primary correctness mechanism. Three attempts may be insufficient. |
| S5 | **No CI/CD, no test framework, no linting** anywhere in Pi-Lisptc. | Entire Pi-Lisptc repo | Phases 0-8 will ship without automated quality gates. Regression risk is high. |
| S6 | **Autolith adaptation track lacks measurable entry criteria** — Phases 9-12 say "after phases 0-7 daily-stable" and "after documented failure" but define no quantitative thresholds. | `Pi-Lisptc/plan/phase-10-bounded-rlm.md` | Risk of premature RLM investment (expensive, complex) or conversely, of never triggering the mechanism that would justify it. |
| S7 | **`packages/ai` in lisptc is completely empty** — All AI orchestration lives in the Pi extension. No standalone agent loop exists outside Pi. | `lisptc/packages/ai/src/index.ts` | If Pi-Lisptc wants to test the mind loop without Pi's TUI, there is no standalone entry point. |
| S8 | **OAuth callback port conflict** — Singleton server on fixed port 8909. Multiple lisptc instances on the same machine collide. | `lisptc/packages/interpreter/src/mcp-broker.ts` | Enterprise/multi-project scenarios break. |
| S9 | **`secretsExtension` doesn't auto-load .env files in AgentRepl** — Only `REPL_*` env vars work. | `lisptc/packages/repl/src/repl.ts`, `lisptc/packages/interpreter/src/secrets.ts` | Secret management for MCP servers (API keys) requires manual env var setup. |
| S10 | **Session server has no authentication** — Any local user can eval code via the Unix socket. | `lisptc/packages/repl/src/session-server.ts` | Security concern if Pi-Lisptc adopts shared sessions. |

### Moderate (Quality/Legibility)

| # | Finding | Source |
|---|---------|--------|
| M1 | `sample.ptc` has stale references and ad-hoc test code at end | `lisptc/examples/sample.ptc` |
| M2 | Duplicate `jsonToLisp`/`jsToLisp` implementations (mcp.ts vs repl.ts) | Both files |
| M3 | No `finally` clause in lisptc's try/catch | `lisptc/packages/interpreter/src/lisp.ts` |
| M4 | `sendWhenIdle` 50ms polling loop in lisp-repl.ts | `lisptc/apps/pi/extension/lisp-repl.ts` |
| M5 | Naive MCP tool search (substring only, no TF-IDF or embeddings) | `lisptc/packages/interpreter/src/mcp.ts` |
| M6 | License not set for Pi-Lisptc | `Pi-Lisptc/README.md` |
| M7 | `steps` counter for REPL loop is local mutable state, lost on extension reload | `lisptc/apps/pi/extension/lisp-repl.ts` |

---

## What's Done Well

1. **Problem diagnosis is excellent.** The six problems (P1-P6) accurately identify real failure modes in current AI coding agents. The framing of "cabinet vs. cortex" is a genuinely useful mental model.

2. **ADR discipline is strong.** Nine ADRs with clear context/decision/consequences. The distinction between "Accepted" (core) and "Proposed" (additive) is well-maintained. ADR-0004 (replace, don't accumulate) prevents a common agent memory failure mode.

3. **Merge-don't-replace is the right call.** ADR-0001 correctly identifies that stock lisptc's prompt replacement would destroy Pi's coding ability. The merge strategy preserves both value propositions.

4. **Autolith adaptation is well-scoped.** Docs/07 and ADRs 0007-0009 correctly identify the specific patterns worth porting (context contributors, revision-gated resources, bounded RLM) while explicitly rejecting the heavy machinery (SBCL, recovery cores, self.* surgery). The "additive only, no platform port" principle is sound.

5. **Non-goals are clearly stated.** "Full Autolith RLM for v1" and "replacing Pi entirely" are explicitly out of scope. This prevents scope creep.

6. **Phase ordering is logical.** Profiles → prompt → safety → providers → MCP → user channel → persistence → reify → harden → (additive). Each phase builds on the previous.

---

## Top 5 Recommendations

1. **Adopt Autolith's prompt cache architecture immediately** — Separate the merged prompt into a stable prefix (Pi coding role + lisptc channel rules) and a volatile suffix (mind_active, *mind/retrieved*, contributor output). Deliver the volatile suffix as a trailing developer/user message, not inside the system prompt. This single change will reduce token costs by 5-10x on cached turns.

2. **Fix C4 before Phase 2: Implement soft error recovery** — Do NOT call `repl.reset()` on eval failure. Instead, catch the error, report it to the model as feedback, and preserve all prior definitions. Only reset on explicit user command or detected image corruption. This is a one-line change in `lisp-repl.ts` with enormous impact on mind persistence.

3. **Pin upstream SHAs now** — Record exact commit hashes for Pi, lisptc, and Vestige. Define a compatibility matrix. Without this, implementation cannot begin responsibly.

4. **Strip irrelevant source files from interpreter prompt payload** — `mcp-broker.ts` (365 lines of worker-thread code) and `mcp-oauth.ts` are invisible to the LLM's output and should not be in the system prompt. This saves ~2-3k tokens per turn with zero downside.

5. **Define quantitative exit criteria for every phase** — Not just "verification" checkboxes, but measurable thresholds: "prompt cache hit rate > 80% on turns 3+", "retry rate < 5% on grammar-constrained providers", "reify recall latency p99 < 200ms".

---

## Document Index

| File | Contents |
|------|----------|
| `00-EXECUTIVE-SUMMARY.md` | This document |
| `01-SOURCE-AUDIT.md` | File-by-file code audit of all three repositories |
| `02-ARCHITECTURE-REVIEW.md` | Architecture critique with revised recommendations |
| `03-ADR-CRITIQUE.md` | ADR-by-ADR analysis with proposed amendments |
| `04-AUTOLITH-FEATURE-MAPPING.md` | Detailed mapping of Autolith patterns to Pi-Lisptc phases |
| `05-ROADMAP-AND-EXECUTION-CRITIQUE.md` | Phase-by-phase execution review with revised plan |
| `06-RISK-REGISTER.md` | Consolidated risk register with mitigations |
| `07-IMPLEMENTATION-PRIORITY.md` | Recommended implementation order with rationale |
| `08-INTERFACES-AND-INVARIANTS.md` | Interface contracts and invariants the implementation must maintain |
| `09-TEST-STRATEGY.md` | Recommended testing approach |
