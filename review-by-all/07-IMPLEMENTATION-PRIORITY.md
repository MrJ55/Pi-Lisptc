# Review-by-All — Implementation Priority

Consolidated effort estimates and critical path.

---
## Effort by Priority

| Priority | Days | Cumulative | Key Deliverables |
|----------|------|-----------|---------------|
| P0: Pre-work | 4 | 4 | SHAs, API verification, token measurement, project scaffolding, CI |
| P1: Fix upstream bugs | 1.5 | 5.5 | Error recovery (0.5d), INTERPRETER_SOURCE_LLM (0.5d), string-trim patch (0.5d) |
| P2: Phase 0+1 (Foundation) | 7 | 12.5 | Scaffold (1d), profiles (0.5d), prompt assembly with cache (3d), measurement (1d), CI (0.5d), verification (1d) |
| P3: Phase 2+3 (Safety + Providers) | 6 | 18.5 | Validation pipeline (1d), error recovery fix (0.5d), retry budget (0.5d), capability registry (0.5d), tool-call mode (1d), cache composition (0.5d), multi-provider testing (1d), retry feedback templates (0.5d) |
| P4: Phase 4+5 (MCP + UX) | 6 | 24.5 | Vestige adapter (1.5d), MCP bootstrap (0.5d), health check (0.5d), reply/halt detection (0.5d), pretty-printer (1d), error display (0.5d), verification (1d) |
| P5: Phase 6+7 (Mind + Memory) | 9 | 33.5 | mind-api.lisp (2d), prelude load/save (1d), disk prefs (0.5d), caps (0.5d), Vestige adapter impl (1.5d), recall with quality threshold (0.5d), note! with queue (1d), Layer 2 injection (1d), bootstrap recall (0.5d), verification (1.5d) |
| P6: Phase 8 (Harden) | 5 | 38.5 | L0/L1 split (1d), sandbox (2d, recommended), constraint adapter (1d), worker isolation (1d, optional) |
| P7: Phase 9 (Contributors) | 6 | 44.5 | Contribution schema (1.5d), resolution pipeline (2d), refactor recall (0.5d), recent-user-ops (0.5d), mind-active contributor (0.5d), injection point (0.5d), budget measurement (0.5d) |
| P8: Phases 10-12 (Additive) | 8 | 52.5 | RLM (5d if needed, unlikely), agenda (1.5d), papercuts (1d), snapshots (2d), skills (1.5d, defer if time) |

## Critical Path

```
P0(4d) → P2(7d) → P3(6d) → P4(6d) → P5(9d) → P7(6d) = 38 days
```

Items NOT on critical path:
- P1 (upstream fixes) — can run in parallel with P0
- P6 (harden) — optional after core works
- P8 (additive) — after gate criteria pass

## Quick Wins (< 1 day each)

1. **Pin upstream SHAs** (0.5d) — Unblocks everything
2. **Patch error recovery** (0.5d) — Prevents mind lobotomy
3. **Create INTERPRETER_SOURCE_LLM** (0.5d) — Saves ~2-3k tokens/turn
4. **Implement prompt layer separation** (1d) — Saves ~180k tokens/10 sessions
5. **Fix string-trim** (0.5d) — Prevents silent data corruption
6. **Set up Vitest + CI** (1d) — Prevents regressions

## Timeline Scenarios

### Single Developer, Focused
- **Core (P0-P6):** ~39 working days (~8 weeks)
- **Full (P0-P8):** ~53 working days (~11 weeks)

### Part-Time (50%)
- **Core:** ~78 working days (~16 weeks)
- **Full:** ~106 working days (~21 weeks)

### With Gate
- Core usable after ~39 days
- Full features after gate criteria pass + 14 days for additive track

## Effort Comparison Across Reviews

| Review | Estimate | Scope | Basis |
|--------|----------|-------|--------|
| Gemini | 18-24 days | Core only | Happy path, no testing overhead |
| Sonnet | ~60 working days (12 weeks at 5d/wk) | Full | 3-month calendar estimate |
| GLM5p3 | 36 days core, 54 full | Both | Detailed task breakdown |
| **Synthesized** | **39 days core, 53 full** | **Both** | Includes upstream fixes, CI, testing, fact-checked corrections |