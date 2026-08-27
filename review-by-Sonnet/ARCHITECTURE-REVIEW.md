# Architecture Review — Pi-Lisptc

## Executive Summary

Pi-Lisptc is a well-structured development plan for extending lisptc (a Lisp-to-TypeScript compiler) with persistent memory ("mind"), vestige reification, and later Autolith-inspired features (context contributors, bounded RLM, soft generations). The architecture shows strong conceptual coherence but has gaps in execution specificity, interface contracts, and testing strategy.

**Overall assessment:** Solid foundation, needs sharper interfaces, more concrete milestones, and explicit risk mitigation.

---

## Strengths

1. **Clear problem framing** — `docs/00-problems-and-goals.md` correctly identifies Pi's context-loss, lack of persistence, and prompt-fragmentation issues.
2. **Phased delivery** — 13 phases (00–12) with logical dependencies; core lisptc features (00–08) separated from Autolith add-ons (09–12).
3. **ADR discipline** — 9 Architecture Decision Records capture key choices (merge-vs-replace, vestige cabinet, validate-before-eval, provider modes).
4. **Upstream awareness** — `docs/UPSTREAM-PINS.md` and explicit lisptc/autolith commit pins show good fork hygiene.
5. **Mind/Vestige model** — `docs/04-mind-vestige-memory.md` articulates a coherent memory model (working set + long-term vestige).

---

## Architectural Gaps

### 1. Interface Contracts Under-Specified

- **Mind API** (`src/prelude/mind-api.lisp`) is a placeholder (570 bytes). No type signatures, error contracts, or persistence semantics.
- **Provider abstraction** (ADR-0005) lacks a formal interface: no `IProvider` definition, no capability matrix, no fallback strategy.
- **Context contributors** (phase-09, ADR-0007) describe "pluggable context sources" but no registration protocol, lifecycle hooks, or conflict resolution.

**Recommendation:** Define TypeScript interfaces in `src/extension/` for:
- `IMindStore` (read/write/forget/compact)
- `IProvider` (capabilities, constraints, rate limits)
- `IContextContributor` (trigger, payload, priority, cache policy)

### 2. Validation Pipeline Ambiguity

ADR-0003 ("validate-before-eval") is critical for safety but underspecified:
- What validator? (schema, type checker, symbolic executor?)
- Where does it run? (compile-time, REPL, CI?)
- What happens on failure? (reject, sandbox, human review?)

**Recommendation:** Add a `docs/08-validation-strategy.md` with:
- Validation layers (syntax, type, effect, resource)
- Tooling choices (TypeScript compiler API, custom AST walker, runtime guards)
- Failure modes and recovery paths

### 3. Persistence Model Risks

Phase-06 ("persistence-mind") proposes SQLite/JSON but:
- No schema versioning strategy
- No migration path for mind evolution
- No concurrency model (single-user assumed?)

**Recommendation:** Specify:
- Schema version + migration functions
- Write-ahead logging or append-only segments for auditability
- Locking strategy for concurrent access (even if single-user now)

### 4. Autolith Integration Surface

Phase-09–12 import Autolith concepts (context contributors, bounded RLM, soft generations) but:
- No feature mapping table (Autolith feature → Pi-Lisptc implementation)
- No compatibility analysis (Common Lisp vs TypeScript runtime)
- No performance budget (Autolith's symbolic ops may not translate 1:1)

**Recommendation:** Create `docs/08-autolith-feature-map.md` with:
- Feature parity table
- Implementation notes (what's native, what's emulated)
- Known limitations and workarounds

---

## Structural Recommendations

### A. Split `src` into Real Packages

Current `src/` is placeholders. Proposed structure:

```
src/
  core/          # lisptc compiler pipeline (forked)
  mind/          # persistence, vestige, memory APIs
  providers/     # provider abstraction + implementations
  extension/     # Pi extension host (if applicable)
  prelude/       # Lisp runtime libraries (mind-api.lisp, etc.)
  tests/         # Unit + integration tests
```

### B. Add Integration Tests Early

No test strategy in phases. Add:
- Phase-01: Prompt assembly tests (golden files)
- Phase-02: Image safety property tests (no eval of untrusted code)
- Phase-04: MCP bootstrap smoke tests
- Phase-06: Mind persistence round-trip tests

### C. Define Exit Criteria per Phase

Each phase needs measurable done-ness:
- "Phase-04 done" = MCP server starts, lisptc compiles example.lisp, REPL responds in <2s
- "Phase-07 done" = Vestige reification round-trips 1000 items, <100ms latency

---

## Comparison with Upstream lisptc

| Aspect | lisptc (upstream) | Pi-Lisptc (fork) |
|--------|-------------------|------------------|
| **Structure** | Monorepo (packages/ai, /interpreter, /repl) | Planned monorepo (src/core, /mind, /providers) |
| **Tooling** | Taskfile, pnpm, biome, knip, husky | Not yet specified (should inherit) |
| **Docs** | CLAUDE.md, devdocs/ | docs/00–07, adr/, plan/ |
| **Tests** | Implicit (standard TS project) | Not yet defined |
| **Persistence** | None (stateless compiler) | SQLite/JSON mind store (phase-06) |
| **Provider Model** | Single (TypeScript backend) | Multi-provider abstraction (ADR-0005) |

**Gap:** Pi-Lisptc inherits lisptc's tooling implicitly but doesn't specify it. Add `package.json`, `Taskfile.yml`, `biome.json` to phase-00 or phase-04.

---

## Autolith Feature Feasibility

| Autolith Feature | Feasibility in TS | Notes |
|------------------|-------------------|-------|
| **Context Contributors** | High | Pure software architecture; TS-friendly |
| **Bounded RLM (Lisp ops)** | Medium | Requires symbolic AST manipulation; feasible with TS compiler API |
| **Soft Generations** | Medium-High | Versioned prompt/memory snapshots; straightforward |
| **Structured Surfaces** | High | UI/UX layer; TS/React-friendly |

**Risk:** Autolith's Common Lisp macros and runtime assumptions may not translate directly. Emulate, don't port blindly.

---

## Verdict

**Architecture quality:** B+ (strong concepts, weak on contracts)
**Execution readiness:** B− (phases clear, exit criteria missing)
**Risk profile:** Medium (persistence, provider abstraction, Autolith translation)

**Top 3 actions:**
1. Define interfaces (IMindStore, IProvider, IContextContributor) before phase-04
2. Add validation strategy doc (ADR-010) before phase-03
3. Create Autolith feature map (docs/08) before phase-09

---

*Generated by Sonnet via GitHub MCP, 2026-08-27*
