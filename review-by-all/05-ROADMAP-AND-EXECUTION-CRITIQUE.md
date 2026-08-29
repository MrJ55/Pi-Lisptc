# Review-by-All — Roadmap and Execution Critique

Revised phase plan incorporating exit criteria from all reviews.

---
## Revised Phase Ordering

```
Phase -1: Pre-work (SHAs, API verification, spikes, scaffolding)
Phase  0:  Baseline & profiles (pin, CI, contract verification)
Phase  1:  Prompt assembly + CACHE SEPARATION + source optimization
Phase  2:  Image safety + ERROR RECOVERY FIX + validation layers
Phase  3:  Provider widening (grammar + tool-call + retry) + IProvider interface
Phase  4:  MCP bootstrap + Vestige adapter + capability grants
Phase  5:  User channel (reply/halt, pretty-printer, error display)
Phase  6:  Persistence (mind-api.lisp, schema v1, prelude, pins) [BOTTLENECK - start schema in Phase 3]
Phase  7:  Vestige reify loop + Layer 2 injection + memory safety pipeline
Phase 8:  Harden (sandbox promoted to recommended, L0/L1 split)
--- GATE: quantitative exit criteria ---
Phase  9:  Context contributors (refactor Phase 7 recall)
Phase 10: Bounded RLM (after documented failure, with architectural fix)
Phase 11: Agenda + papercuts
Phase 12: Soft generations + skills
```

## Key Changes from Original Plan

| Change | Source | Rationale |
|---|---|---|
| Insert Phase -1 | GLM5p3 | Unblocks all implementation |
| Merge cache architecture into Phase 1 | GLM5p3 + Autolith | Highest-impact optimization |
| Merge error recovery into Phase 2 | GLM5p3 + Luna | Addresses the #1 runtime risk |
| Add `tool-call` mode to Phase 3 | GLM5p3 | Most reliable for OpenAI/Anthropic |
| Add Vestige adapter to Phase 4 | GLM5p3 + Sonnet | Decouples from API instability |
| Promote sandbox to recommended | Luna + Terra | Security gate for v1 |
| Start schema design in Phase 3 | Sonnet | Phase 6 is THE bottleneck |
| Define quantitative exit criteria | All 5 | Measurable done-ness |

## Exit Criteria Per Phase

### Phase -1
- [ ] All upstream SHAs pinned in UPSTREAM-PINS.md
- [ ] Pi's `buildSystemPrompt` contract verified (customPrompt + project context)
- [ ] INTERPRETER_SOURCE token cost measured
- [ ] Vestige MCP tool names documented
- [ ] Pi trailing message support verified (or workaround designed)
- [ ] Node.js project initialized (package.json, tsconfig, Vitest)

### Phase 0
- [ ] `pi-default` profile: tools NOT cleared, system prompt NOT modified
- [ ] `lisp-mind` profile: tools cleared, system prompt merged
- [ ] Both profiles launch via their scripts
- [ ] `opencode-go-cache` coexists with pi-lisptc without conflicts
- [ ] CI passes: typecheck + lint + unit tests
- [ ] Upstream lisptc test suite passes unchanged


### Phase 1
- [ ] Merged prompt contains Pi coding core markers
- [ ] Merged prompt contains lisptc channel markers
- [ ] Merged prompt contains INTERPRETER_SOURCE_LLM (excludes irrelevant files)
- [ ] Merged prompt does NOT contain volatile mind state
- [ ] Token count of Layer 0 logged
- [ ] Cache hit rate measured (target: >80% on turns 3+)
- [ ] `pi-default` still works (no regression)

### Phase 2
- [ ] Malformed output never reaches eval (parse error → retry)
- [ ] Runtime error (EvalException) preserves definitions
- [ ] Only catastrophic corruption triggers reset
- [ ] After reset, prelude reload attempted
- [ ] Retry counter works (configurable budget per provider)
- [ ] 100+ turns without REPL corruption

### Phase 3
- [ ] Fireworks (grammar), OpenAI/Anthropic (tool-call), one fallback (retry) all work
- [ ] `tool-call` mode: single `eval_lisp_form` tool, forced tool_choice
- [ ] Provider swap changes only adapter/config
- [ ] Cache fields preserved across all modes
- [ ] Retry rate < 5% on grammar-constrained providers


### Phase 4
- [ ] MCP servers (Vestige, filesystem) load in-image
- [ ] Outer tool list stays empty
- [ ] Vestige adapter with retry, fallback, version detection
- [ ] MCP health check on bootstrap
- [ ] Compile latency <2s (Sonnet SLO)

### Phase 5
- [ ] `(reply "test-visible")` → user sees test-visible
- [ ] `(halt ...)` → session stops appropriately
- [ ] Structured values are pretty-printed
- [ ] Error display is structured (not raw stack traces)

### Phase 6
- [ ] mind-api.lisp fully implemented (all stubs replaced)
- [ ] `mind/reify!` replaces `*mind/retrieved*` (call twice → only second persists)
- [ ] Pins within cap (40); oldest evicted on overflow
- [ ] Prefs persist across restart
- [ ] Schema v1 defined with migration function
- [ ] Round-trip persistence test passes

### Phase 7
- [ ] Auto-recall on user message
- [ ] Recall quality threshold filters garbage
- [ ] mind_active delivered as Layer 2 (trailing message)
- [ ] 8-stage memory safety pipeline
- [ ] Ingest failure queued, retried next turn
- [ ] Vestige down → empty recall → agent continues
- [ ] Recall latency p99 < 200ms
- [ ] 50+ turn sessions without crash

### Phase 8
- [ ] L0/L1 prompt split (if cache hit rates < 80%)
- [ ] Sandbox eval: commit-on-success pattern
- [ ] Constraint adapter package shared across modes


### Gate (Phases 0-8)
- [ ] All above checkboxes pass
- [ ] Prompt cache hit rate > 80% on turns 3+
- [ ] Retry rate < 5% on grammar providers
- [ ] Recall latency p99 < 200ms
- [ ] Zero session crashes from mind corruption in 50+ turn sessions
- [ ] 3+ users have used lisp-mind for real work 1+ week each

### Phase 9
- [ ] Contributor registry with registration protocol
- [ ] Resolution pipeline (invoke → merge → filter → dedup → supersede → budget → render)
- [ ] Mandatory total ≤ 8k chars; advisory ≤ ~1,500 tokens
- [ ] Phase 7 recall refactored as `related-memories` contributor
- [ ] `recent-user-ops` contributor (ring buffer of 8-16 validated evals)

### Phase 10
- [ ] Only triggered after documented long-context failures
- [ ] Budget: calls, tokens, depth — host-enforced
- [ ] Sub-requests bypass interpreter's Atomics.wait (use Pi provider API)
- [ ] Parent receives result; child state is isolated


### Phase 11
- [ ] `*mind/agenda*` alist with Vestige persistence
- [ ] `mind/papercut!` with closure requirement
- [ ] Cap 20 open papercuts

### Phase 12
- [ ] Snapshot: `*mind/user*`, `*mind/pins*`, `*mind/project*`, skill metadata
- [ ] Restore: load-into-REPL, not process reboot
- [ ] Retention: last 10 snapshots
- [ ] No API keys in snapshot files

## Effort Estimates (Consolidated)

| Priority | Days | Key Items |
|---|---|---|
| P0: Pre-work | 4 | SHAs, API verification, spikes, scaffolding |
| P1: Fix upstream | 1.5 | Error recovery, source optimization, string-trim |
| P2: Foundation (0+1) | 7 | Scaffold, profiles, prompt assembly + cache |
| P3: Safety + Providers (2+3) | 6 | Validation, error recovery, 3 provider modes |
| P4: MCP + UX (4+5) | 6 | Vestige adapter, MCP bootstrap, user channel |
| P5: Mind + Memory (6+7) | 9 | Mind API, persistence, Vestige reify, Layer 2 |
| P6: Harden (8) | 5 | Sandbox (recommended), L0/L1, constraint adapter |
| **Core total** | **~38.5** | |
| P7: Contributors (9) | 6 | Registry, pipeline, refactored recall |
| P8: Additive (10-12) | 8 | RLM (if needed), agenda, papercuts, snapshots |
| **Full total** | **~53** | |