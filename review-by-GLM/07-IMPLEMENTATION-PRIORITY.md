# Review-by-GLM5p3 — Implementation Priority

Recommended implementation order with rationale, estimated effort, and dependencies.

---

## Priority 0: Pre-Work (Before Phase 0)

| Task | Effort | Rationale |
|------|--------|----------|
| Pin upstream SHAs (Pi, lisptc, Vestige) | 0.5 day | Blocks all implementation. Record in UPSTREAM-PINS.md. |
| Read Pi's `buildSystemPrompt` source | 0.5 day | Verify customPrompt contract. Document exact behavior. |
| Measure INTERPRETER_SOURCE token cost | 0.5 day | Informs prompt budget decisions for every subsequent phase. |
| Spike: Vestige MCP tool discovery | 0.5 day | Document exact tool names, schemas, and calling conventions. |
| Spike: Pi trailing message support | 0.5 day | Test whether Pi supports injecting developer/user messages after history. |
| Initialize Node.js project | 0.5 day | package.json, tsconfig, dependencies. |
| Set up Vitest + basic CI | 1 day | Even a single failing test prevents regressions. |

**Total Priority 0: ~4 days**

---

## Priority 1: Fix Critical Upstream Issues

| Task | Effort | Rationale |
|------|--------|----------|
| Patch `lisp-repl.ts` error recovery (R01) | 0.5 day | Without this, the mind resets on any runtime error. This is the single most impactful code change. |
| Create `INTERPRETER_SOURCE_LLM` (R06) | 0.5 day | Exclude irrelevant source files. Saves ~2-3k tokens/turn. |
| Fix `string-trim` bug (R10) | 0.5 day | Silent data corruption. Simple fix. |

**Total Priority 1: ~1.5 days**

---

## Priority 2: Phase 0 + Phase 1 (Foundation)

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| Scaffold extension package | 1 day | P0 | Phase 0 T0.3 |
| Implement prompt layer separation | 1 day | P0 (spike) | **Highest-impact architectural change.** Must be in Phase 1. |
| Assemble merged prompt (Layer 0) | 1 day | P0, P1 | Phase 1 T1.1-T1.3 with optimized source |
| before_agent_start integration | 0.5 day | P0 | Phase 1 T1.4 |
| setActiveTools([]) | 0.5 day | P0 | Phase 1 T1.5 |
| Launch scripts (both profiles) | 0.5 day | P0 | Phase 0 T0.4 |
| Profile switching test | 0.5 day | P0 | Verify pi-default and lisp-mind both work |
| **Prompt token measurement** | 0.5 day | P0 | Log total tokens, document remaining budget |
| **Cache hit rate measurement** | 0.5 day | P0 (spike) | Verify Layer 0 is actually cached |

**Total Priority 2: ~6 days**

---

## Priority 3: Phase 2 + Phase 3 (Safety + Providers)

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| stripFences + validateForm | 1 day | P2 | Phase 2 T2.1-T2.2 |
| message_end pipeline with retry | 1 day | P2 | Phase 2 T2.3 |
| Configurable retry budget | 0.5 day | P2 | R08 mitigation |
| Provider capability registry | 0.5 day | P2 | Phase 3 T3.1 |
| Implement `tool-call` mode | 1 day | P2 | For OpenAI/Anthropic — most reliable constrained output |
| Conditional grammar mode | 0.5 day | P2 | Phase 3 T3.2 (already exists, needs parameterization) |
| Cache composition testing | 0.5 day | P2 | Verify cache + grammar/tool-call interaction |
| Multi-provider verification | 1 day | P2 | Test 3 providers: grammar, tool-call, retry |

**Total Priority 3: ~6 days**

---

## Priority 4: Phase 4 + Phase 5 (MCP + UX)

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| Vestige adapter interface | 1 day | P0 (spike) | R04 mitigation. Decouples from Vestige API changes. |
| MCP bootstrap config | 0.5 day | P2 | Phase 4 T4.1-T4.2 |
| MCP health check | 0.5 day | P4 | Phase 4 addition |
| reply/halt detection | 0.5 day | P2 | Phase 5 T5.1 |
| Pretty-printer | 1 day | P2 | Phase 5 T5.2 |
| Error display format | 0.5 day | P2 | Phase 5 addition |

**Total Priority 4: ~4 days**

---

## Priority 5: Phase 6 + Phase 7 (Mind + Memory)

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| Implement mind-api.lisp | 2 days | P2 | Phase 6 T6.1 — the core Lisp API |
| Prelude load/save | 1 day | P5 | Phase 6 T6.2-T6.4 |
| Vestige adapter implementation | 1.5 days | P4 | Phase 7 T7.1 — recall with retry, fallback, quality threshold |
| Recall trigger with quality threshold | 0.5 day | P5 | R20 mitigation |
| mind/note! with ingest queue | 1 day | P5 | Phase 7 T7.3 |
| Bootstrap recall | 0.5 day | P5 | Phase 7 T7.4 |
| **Layer 2 injection for mind_active** | 1 day | P2, P5 | **Critical:** deliver mind state as trailing message |
| Verification with quality metrics | 1 day | P5 | Phase 7 T7.5-T7.6 |

**Total Priority 5: ~8.5 days**

---

## Priority 6: Phase 8 (Harden)

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| L0/L1 prompt split (refinement) | 1 day | P2, P5 | Optimize further if cache hit rates are low |
| Sandbox eval | 2 days | P5 | **Promoted from optional to recommended.** Commit-on-success pattern. |
| Constraint adapter package | 1 day | P3 | Shared provider logic |
| Worker isolation | 2 days | P5 | Subprocess for untrusted MCP |

**Total Priority 6: ~6 days (sandbox recommended, others optional)**

---

## Priority 7: Phase 9 (Context Contributors)

**Entry criteria (all must pass):**
- Phases 0-7 all verification checkboxes green
- Prompt cache hit rate > 80% on turns 3+
- Retry rate < 5% on grammar-constrained providers
- Recall latency p99 < 200ms
- Zero session crashes from mind state corruption in 50+ turn sessions

| Task | Effort | Depends On | Rationale |
|------|--------|-----------|----------|
| Contribution schema + registry | 1.5 days | P5 | TypeScript implementation of Autolith's pattern |
| Resolution pipeline | 2 days | P7 | Dedup, supersede, budget, render |
| Refactor Phase 7 recall as contributor | 0.5 day | P7 | related-memories built-in |
| recent-user-ops contributor | 0.5 day | P7 | Ring buffer of validated evals |
| mind-active contributor | 0.5 day | P7 | Compact mind state dump |
| Injection point | 0.5 day | P2 | Trailing developer message |
| Budget measurement | 0.5 day | P7 | Verify advisory budget enforcement |

**Total Priority 7: ~6 days**

---

## Priority 8: Phases 10-12 (Additive)

| Phase | Task | Effort | Depends On | Rationale |
|-------|------|--------|-----------|----------|
| 10 | Bounded RLM (if measured need) | 5 days | P7 | High effort, high risk. Only after documented long-context failures. |
| 11 | Agenda surface | 1.5 days | P5 | Simple alist + Vestige persistence |
| 11 | Papercut surface | 1 day | P5 | Simple alist + Vestige persistence |
| 12 | Soft generations/snapshots | 2 days | P5 | Prelude serialization + restore |
| 12 | Skill loading | 2 days | P5 | Directory scanning + eval |

**Total Priority 8: ~11.5 days (RLM unlikely for v1)**

---

## Effort Summary

| Priority | Days | Cumulative |
|----------|------|-----------|
| P0: Pre-work | 4 | 4 |
| P1: Fix critical upstream | 1.5 | 5.5 |
| P2: Foundation (Phase 0+1) | 6 | 11.5 |
| P3: Safety + Providers (Phase 2+3) | 6 | 17.5 |
| P4: MCP + UX (Phase 4+5) | 4 | 21.5 |
| P5: Mind + Memory (Phase 6+7) | 8.5 | 30 |
| P6: Harden (Phase 8) | 6 | 36 |
| P7: Contributors (Phase 9) | 6 | 42 |
| P8: Additive (Phase 10-12) | 11.5 | 53.5 |

**Core (P0-P6): ~36 days**
**Full (P0-P8): ~54 days**

These estimates assume a single experienced developer full-time.

---

## Critical Path

The longest dependency chain:
```
P0 (4d) → P2 (6d) → P3 (6d) → P4 (4d) → P5 (8.5d) → P7 (6d) = ~34.5 days
```

The items NOT on the critical path:
- P1 (upstream fixes) — can be done in parallel with P0
- P6 (harden) — optional, after core works
- P8 (additive) — after gate criteria pass

---

## Quick Wins (< 1 day each, high impact)

1. **Patch error recovery** (0.5d) — Prevents mind lobotomy
2. **Pin upstream SHAs** (0.5d) — Unblocks implementation
3. **Create INTERPRETER_SOURCE_LLM** (0.5d) — Saves ~2-3k tokens/turn immediately
4. **Implement prompt layer separation** (1d) — Saves ~180k tokens per 10-turn session
5. **Fix string-trim bug** (0.5d) — Prevents silent data corruption
