# Autolith feature adaptation (additive track)

This document maps [Autolith](https://github.com/lambda-symbolics/autolith) capabilities to **optional** Pi-Lisptc improvements. It does **not** change phases 0–8 deployment. Full Autolith (SBCL live agent OS, recovery cores, `self.*` surgery) remains a non-goal for the core path.

**Constraint:** Adapt **behaviors and interfaces**, not the Autolith runtime, sexp-store layout, or SBCL image model. lisptc + Pi + Vestige stay the substrate.

---

## Feature map

| Autolith concept | What it solves | Pi-Lisptc adaptation | When |
|------------------|----------------|----------------------|------|
| `memory-related-context` | Lexical top-k related memories each request | Already core of phase 7 (host auto-recall + reify). Optional: richer ranking / stopword lists | Phase 7 (done in core); refine in phase 9 |
| Context **contributors** | Turn-local instruction + evidence with priority, lifetime, advice budget | Host-side contributor registry; inject as mind_active / developer block | Phase 9 |
| Mandatory vs advice classes | Critical evidence cannot be budget-dropped | `class: mandatory` vs `advice` with token budget | Phase 9 |
| Recent **user-operations** | Local Lisp/shell ops visible to model next turn | Log last N validated evals; inject as mandatory evidence | Phase 9 |
| Ephemeral notes | `define-context-contributor` style turn advice | Prelude + host registry of contributor fns | Phase 9 |
| **RLM** `infer` / `rlm-map` / `rlm-complete` | Context larger than window as environment | Bounded Lisp ops over Vestige/files; private sub-conversation optional | Phase 10 |
| Content-addressed large objects | Label/size/digest in prompt; body outside | Hash + path or Vestige id; model sees descriptor | Phase 10 |
| **Agendas** | Versioned workspace plans | `*mind/agenda*` + Vestige tags; thin host helpers | Phase 11 |
| **Papercuts** | User-visible defect + closure tombstones | `mind/papercut!` → Vestige ingest; list/close ops | Phase 11 |
| Generations / recovery image | Rollback after lobotomy | Soft: session snapshot of prelude + pins; optional REPL fork | Phase 12 |
| `self.*` / private commits | Auditable self-mod of agent | Out of scope for Pi extension; skills/prelude only | Never (core) |

---

## Principles for adaptation

1. **Additive only** — phases 9+ run after 0–8 exit criteria pass daily use.
2. **No platform port** — do not vendor Autolith sources or require SBCL.
3. **Host enforces** — same rule as Vestige reify: contributors and RLM budgets are host-controlled, not “hope the model calls the tool.”
4. **Budget first** — every contributor and every RLM frame has explicit token/call/depth caps.
5. **Replace, don’t accumulate** — turn contributions expire; durable state stays in Vestige or capped mind namespaces.
6. **Measure need** — RLM (phase 10) only after measured failures on long-context coding tasks with phase 7 memory alone.

---

## Relationship to core goals

| Core goal | Autolith track contribution |
|-----------|----------------------------|
| G3 Living mind | Richer turn-local evidence without bloating REPL |
| G4 Relevant recall | Contributor pattern generalizes auto-recall |
| G5 No image trash | RLM frames isolated; optional sandbox eval already phase 8 |
| G8 Controlled evolution | Papercuts/agenda give structured durable writes |
| Non-goal: full Autolith | Explicit — recovery cores and `self.*` stay external inspiration |

---

## Upstream reading (inspiration only)

- Autolith `src/agent/memory-context.lisp` — lexical rank, top 6, excerpt limits  
- Autolith context contributor protocol (priority, lifetime, class, supersedes)  
- Autolith `docs/rlm.org` — `infer`, budgets, content-addressed objects  
- Autolith architecture: conversations / memories / agendas / papercuts separation  

Pin commit SHAs in `docs/UPSTREAM-PINS.md` when implementing phases 9–12 for reference, not as dependencies.

---

## Exit of this track

Document which subsets shipped. Core Pi-Lisptc remains valuable if only phases 0–8 ship.
