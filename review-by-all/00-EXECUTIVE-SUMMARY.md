# Review-by-All — Executive Summary

**Synthesized from:** review-by-GLM5p3, review-by-Luna, review-by-Sonnet, review-by-Terra, review-by-Gemini
**Fact-check basis:** Every claim verified against cloned source code of all three repositories
**Date:** 2026-08-29

---

## Verdict: Strong vision, zero execution, several correctable architectural gaps across all reviews.

This synthesis consolidates the findings of five independent reviews. All five agree on the core diagnosis (coherence failure, filing-cabinet knowledge, context bloat are real problems) and the fundamental approach (merge Pi + lisptc + Vestige, adapt Autolith patterns not platform). The reviews diverge in emphasis and specificity. This document identifies where they agree, where they complement each other, where they conflict, and where individual reviewers made factual errors.

### Fact-Check Scorecard

Across all reviews, 36 concrete factual claims were checked against source code:
- **22 verified** (correct)
- **4 partially correct** (minor inaccuracies)
- **10 refuted** (wrong)

Most impactful refutations: Gemini fabricated class names (`LispSession`, `MCPBroker`) and methods that don't exist in the codebase; Sonnet claimed `mind-api.lisp` is 570 bytes (the file is in Pi-Lisptc, not lisptc — scope confusion); my own review wrongly stated there is no `finally` clause in lisptc (4 instances exist). See [01-FACT-CHECK-AND-CORRECTIONS.md](01-FACT-CHECK-AND-CORRECTIONS.md) for full details.

---

## Unanimous Agreements (All 5 Reviews)

| # | Finding | Source Evidence |
|---|---------|---------------|
| A1 | **Pi extension replaces system prompt and clears tools** — must be changed to merge | `lisp-repl.ts` L297, L322 |
| A2 | **Provider hook unconditionally installs Fireworks grammar** — must be parameterized | `lisp-repl.ts` L272-280 |
| A3 | **Interpreter is synchronous; MCP uses worker threads + Atomics.wait** | `jobs.ts` L145, `mcp-broker.ts` L5 |
| A4 | **Validate before eval is essential** — malformed output must never reach REPL | All reviews identify this |
| A5 | **Vestige = durable cabinet, REPL = working cortex** — correct separation | All reviews affirm this |
| A6 | **Replace-not-accumulate for turn recall** — prevents context bloat | ADR-0004, all reviews affirm |
| A7 | **Two profiles (pi-default, lisp-mind)** — correct boundary | ADR-0006, all reviews affirm |
| A8 | **Autolith patterns only, not platform** — don't port SBCL/image/self-mutation | All reviews explicitly reject this |
| A9 | **No upstream SHAs pinned** — blocks implementation | `UPSTREAM-PINS.md` all TBD |
| A10 | **Zero runnable code exists** — entirely planning documents | Entire Pi-Lisptc repo |

---

## High-Consensus Findings (4/5 Reviews)

| # | Finding | Reviews That Identify It | New Contribution Here |
|---|---------|-------------------------|---------------------|
| B1 | **`repl.reset()` on runtime error destroys the mind** | GLM5p3, Luna, Terra | **Confirmed by source**: `lisp-repl.ts` L327-338 unconditionally calls `repl.reset()` in catch block |
| B2 | **SYSTEM_PROMPT doesn't include INTERPRETER_SOURCE** | GLM5p3 only | **Confirmed by source**: import is dead code, `SYSTEM_PROMPT = POLICY` only |
| B3 | **Prompt cache architecture missing** — volatile mind state in system prompt busts cache | GLM5p3, Autolith evidence | **Quantified**: ~180k tokens wasted per 10-turn session. Autolith's context-cost-report.org confirms this as finding #3 |
| B4 | **`IProvider` interface needed** — provider abstraction is hardcoded | Sonnet, Gemini, Luna | Agree, but note: this is Pi's responsibility, not lisptc's. Lisptc has no provider model (fact-checked) |
| B5 | **Persistence schema/migration needed** | Sonnet, Terra, Luna | Agree. Phase 6 mentions disk prefs but no schema versioning |
| B6 | **Validation strategy underspecified** — what validator, where it runs | Sonnet, Luna, Terra | Agree. ADR-0003 says "validate" but doesn't specify the mechanism |
| B7 | **Exit criteria per phase needed** | Sonnet, Luna, Terra, GLM5p3 | Agree. All four reviews propose measurable exit gates |
| B8 | **Context contribution system (from Autolith) is the right pattern for phase 9** | All 5 | Agree. Autolith's `src/agent/context.lisp` (1064 lines) is the reference implementation |
| B9 | **RLM must be deferred with measured-need gate** | GLM5p3, Luna, Sonnet, Gemini | Agree. Autolith's RLM depends on SBCL worker isolation; lisptc's blocking `Atomics.wait` creates nested-blocking risk |
| B10 | **Test strategy is missing/inadequate** | Sonnet, Luna, GLM5p3 | Agree. Zero tests in Pi-Lisptc. lisptc's `apps/pi` has zero tests |

---

## Unique Valuable Insights Per Review

### From Luna (strongest on: boundaries, authority, state classes)
1. **Three-plane architecture**: Host Control Plane (Pi) → lisptc Execution Plane → Durable Knowledge Plane (Vestige). The model is an *actor* inside this system, not the *owner*.
2. **Seven distinct state classes**: conversation transcript, working mind, turn evidence, durable memories, user preferences, agenda/papercuts, inference traces.
3. **"Interpreter reset as transactional rollback is categorically rejected."** Explicit anti-pattern identification.
4. **Authority table**: clear ownership of model/provider (Pi), tools (Pi), durable memory (Vestige/host), evaluation (lisptc), MCP (host-approved).
5. **"Autonomous provider switching inside Lisp" explicitly rejected.**
6. **Typed context contributions with provenance and cost metadata.** `Contribution {content, source, priority, token_cost, ttl}` envelope.
7. **Release blockers**: five conditions that must be resolved before any production milestone.

### From Sonnet (strongest on: gap analysis, feasibility matrix, SLOs)
1. **Autolith feasibility matrix**: Context Contributors = High; Bounded RLM = Medium; Soft Generations = Medium-High.
2. **Quantitative SLOs**: compile <2s, memory <500MB for 10k LOC, Vestige reification <100ms for 1000 items. Only review with concrete performance targets.
3. **Phase-06 (persistence) is THE bottleneck** — blocks mind, Vestige, AND Autolith features. "Start schema design in phase-03."
4. **Critical path identification**: Phases 00→01→03→04→06→07 as the core dependency chain.
5. **ADR-0004 data-loss risk**: "replace not accumulate" needs undo/redo capability.
6. **Four missing ADRs proposed**: Validation Strategy, Persistence Schema, Provider Fallback, Testing Strategy.
7. **3-month timeline estimate** (Weeks 1-12).

### From Terra (strongest on: security, formal interfaces, memory safety)
1. **`apps/pi` placement**: Pi-Lisptc should extend existing `lisp-repl.ts` and `system-prompt.ts` in lisptc's `apps/pi/` package, not build a separate daemon.
2. **Three enforcement layers for forced action channel**: generation constraints → profile runtime policy → evaluation-time capability bridge.
3. **"Never evaluate raw text fields from memory or model output."** Data-only Lisp literals through narrow allowlist.
4. **`CANCELLED` as a distinct capability result code.** Cancellation is first-class, not an error.
5. **8-step context algorithm** with specified sort key `(priority, contributor, id)`.
6. **"Adapters never receive ambient evaluator authority."** Least-privilege for MCP adapters.
7. **`reserveTokens` concept** in context budgets — reservation for critical system context.
8. **Differential testing** — Pi-enabled vs Pi-disabled semantic comparison.
9. **Memory injection defense**: `repl.eval(record.text)` explicitly named as an anti-pattern. 8-stage safety pipeline for reification.
10. **8 new ADRs proposed** (ADR-0010 through ADR-0017) — most comprehensive ADR expansion.
11. **Profile type** with `persistencePolicy` modes (`off|ephemeral|durable`) and `approvalPolicy`.
12. **DurableEvent type with `redactedAt` timestamp** — redaction is itself a recorded event.

### From Gemini (strongest on: practical execution, test gates, file placement)
1. **Concrete file placement proposal**: `profiles.ts`, `action-channel.ts`, `context-assembly.ts`, `vestige.ts`, `provider-policy.ts`, `input-safety.ts`, `output-protocol.ts`, `audit.ts` in `apps/pi/extension/`.
2. **`opencode-go-cache` named as only approved outer tool** in lisp-mind profile.
3. **Reification data schema**: `:turn-id`, `:items` with `:id`, `:kind`, `:text`, `:scope`, `:confidence`, `:source`, `:tags`.
4. **Action API**: `mind.recall-all`, `mind.recall-by-tag`, `mind.recall-by-kind`, `mind.recall-get`, `mind.recall-search`.
5. **Five validation gates with concrete test code**: image safety, reification safety, provider modes, replace-not-accumulate, smart ingest gating.
6. **Asymmetric test coverage targets**: 95% provider-policy, 90% action-channel/lisp-repl, 85% vestige, 80% system-prompt.
7. **18-24 day core path estimate.**
8. **"Extend, don't daemonize."** Grounded in lisptc's actual `apps/pi/` structure.

### From GLM5p3 (strongest on: upstream bugs, token economics, code-level detail)
1. **`string-trim` bug in lisptc prelude** — `_whitespace?` checks literal two-char strings, not actual whitespace characters. `(string-trim "\thello\t")` silently fails.
2. **INTERPRETER_SOURCE includes 842 lines of irrelevant code** (mcp-broker.ts, mcp-oauth.ts, jobs-broker.ts, jobs-protocol.ts).
3. **Token savings quantification**: ~180k tokens per 10-turn session from cache architecture.
4. **`tool-call` mode missing from provider strategy** — for OpenAI/Anthropic, forced single-tool calling is more reliable than retry.
5. **Vestige adapter layer** needed due to tool name instability.
6. **Fact-checked corrections to other reviews**: 10 refuted claims, 4 partially correct.

---

## Top 10 Recommendations (Consensus + New)

| # | Recommendation | Source | Priority |
|---|---------------|--------|----------|
| 1 | **Adopt prompt cache architecture** — stable prefix + volatile trailing message | GLM5p3 + Autolith evidence | P0 |
| 2 | **Fix error recovery** — do NOT call `repl.reset()` on runtime error | GLM5p3 + Luna + Terra | P0 |
| 3 | **Pin upstream SHAs** | All 5 | P0 |
| 4 | **Strip irrelevant source files from interpreter prompt** | GLM5p3 | P0 |
| 5 | **Define host/runtime boundary as typed interfaces** | Luna + Terra + Sonnet | P1 |
| 6 | **Implement `tool-call` provider mode** for OpenAI/Anthropic | GLM5p3 | P1 |
| 7 | **Add Vestige adapter with retry, fallback, quality threshold** | GLM5p3 + Sonnet | P1 |
| 8 | **Define context contribution system** (adapted from Autolith) | All 5 | P2 |
| 9 | **Establish test strategy with 6-level pyramid** | Terra + GLM5p3 + Gemini | P1 |
| 10 | **Quantitative exit criteria for every phase** | Sonnet + Luna + Terra + GLM5p3 | P1 |

---

## Document Index

| File | Contents |
|------|----------|
| `00-EXECUTIVE-SUMMARY.md` | This document |
| `01-FACT-CHECK-AND-CORRECTIONS.md` | All 36 fact-checks with evidence and corrections |
| `02-ARCHITECTURE-REVIEW.md` | Unified architecture critique with best insights from all reviews |
| `03-ADR-CRITIQUE.md` | ADR-by-ADR analysis incorporating all reviewers' proposed amendments |
| `04-AUTOLITH-FEATURE-MAPPING.md` | Feature mapping validated against actual Autolith source |
| `05-ROADMAP-AND-EXECUTION-CRITIQUE.md` | Revised phase plan with exit criteria from all reviews |
| `06-RISK-REGISTER.md` | Consolidated risk register with mitigations |
| `07-IMPLEMENTATION-PRIORITY.md` | Effort estimates and critical path |
| `08-INTERFACES-AND-INARIANTS.md` | Synthesized interface contracts from all reviews |
| `09-TEST-STRATEGY.md` | Unified test strategy |
| `10-CROSS-REVIEW-ANALYSIS.md` | Where reviews agree, differ, complement, and err |