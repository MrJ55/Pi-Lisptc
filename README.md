# Pi-Lisptc

**Enhance [Pi](https://github.com/earendil-works/pi) with [lisptc](https://github.com/1hachem/lisptc): a forced programmatic mind (REPL cortex) plus durable associative memory (Vestige), without throwing away Pi’s coding performance.**

Target repo: `https://github.com/MrJ55/Pi-Lisptc`

---

## Problems this project addresses

1. **Coherence failure** — Models forget module flow, duplicate triggers/gates, lose design intent while generating code.
2. **Filing-cabinet problem** — Wikis, graphs, skills, and external memories are optional; models ignore them unless forced.
3. **Schema / extension bloat** — Many Pi extensions and MCP tool schemas consume context (~30k+) and still don’t form one mind.
4. **Human bandwidth** — Human review cannot keep pace with AI code generation; the “image” of how the system works must live in an executable mind, not only docs.
5. **Provider lock-in** — Grammar-constrained Lisp (e.g. Fireworks) is powerful but not universal; OpenCode Go and others need validate+retry.
6. **Prompt replace risk** — Stock lisptc *replaces* Pi’s system prompt and clears tools, which strips what Pi coding performance depends on.

## Goals

| Goal | Success signal |
|------|----------------|
| **G1** Keep Pi coding ability | Merged system prompt retains Pi role, AGENTS.md, cwd, concise/path guidelines |
| **G2** Forced action channel | In `lisp-mind` profile, actions go through Lisp eval (MCP-in-image), not 50 outer tools |
| **G3** Living mind | Session REPL holds skills/state; durable facts in Vestige; **reify** each turn |
| **G4** Relevant recall | Host auto-recalls from Vestige; injects top-k; does not dump whole memory |
| **G5** No image trash | Validate/parse before session eval; retries; optional sandbox |
| **G6** Any major provider | grammar \| strict-tool \| validate+retry; cache extension preserved |
| **G7** Readable UX | `(reply)` / `(halt)` + host pretty-print |
| **G8** Self-improvement without noise | Mind epilogue → gated `smart_ingest`; reify **replaces** turn set; pins capped |
| **G9** Two profiles | `lisp-mind` vs `pi-default` so classic Pi remains available |

## Non-goals (near term / core path)

- Full Autolith RLM / recovery generations / `self.*` agent surgery as **required** for v1  
- Prime Agent Continual Harness parity  
- Replacing Pi entirely with a Lisp-only product  
- Moving `opencode-go-cache` into Lisp  

**Additive track (phases 9–12):** optional Autolith-*inspired* adaptations (context contributors, bounded RLM Lisp ops, agendas/papercuts, soft snapshots). See `docs/07-autolith-adaptation.md`. These follow core phases 0–8 and do not change core deployment.  

## Architecture (one picture)

```text
User message
    |
    |─► Host: Vestige recall (auto) ──► mind/reify!  (*mind/retrieved* REPLACE)
    |─► Inject mind_active (budget-capped)
    |
    ▼
Model (merged Pi coding + lisptc channel + interpreter source)
    |  output = Lisp only (lisp-mind profile)
    ▼
Validate → eval in REPL → MCP tools as Lisp functions
    |
    |─► (reply …) / pretty-print  (+ host UX prefs)
    |─► mind epilogue → smart_ingest | skip  (gated)
```

- **lisptc image** = working cortex (live `defun`, turn state, hot prefs)  
- **Vestige** = durable associative cabinet (hybrid search, FSRS, smart_ingest)  
- **Pi** = harness, TUI, providers, extensions (`opencode-go-cache`, etc.)

## Repository layout

```text
Pi-Lisptc/
├── README.md                 ← you are here
├── docs/                     ← deep background & context
├── adr/                      ← architecture decision records
├── plan/                     ← phased implementation (task lists for implementers)
├── src/                      ← extension, prelude, host helpers (to be built)
└── scripts/                  ← profile launch helpers
```

## Phased plan (summary)

| Phase | Name | Outcome |
|-------|------|---------|
| 0 | Baseline & profiles | `pi-default` vs `lisp-mind` launch paths |
| 1 | Prompt assembly | `buildSystemPrompt` merge + full interpreter source (optimize later) |
| 2 | Image safety | Validate-before-eval; retry; no trash |
| 3 | Provider widening | grammar / tool / retry modes + cache coexistence |
| 4 | MCP bootstrap | Vestige + fs (etc.) in-image; thin outer tools |
| 5 | User channel | `reply`/`halt` + pretty-print |
| 6 | Persistence | Prelude load/save; pins; session continuity |
| 7 | Vestige reify loop | Auto-recall → reify → act → ingest |
| 8 | Optional harden | Sandbox, L0/L1 prompt, workers (no RLM here) |
| **9–12** | **Autolith adaptation (additive)** | Contributors, bounded RLM, agenda/papercuts, soft generations |

Detailed task lists: **[plan/](./plan/)**. Core path is phases 0–8; additive track is optional and sequential after core.

## Key ADRs

- [ADR 0001](./adr/0001-merge-prompt-not-replace.md) — Merge Pi prompt; do not stock-replace  
- [ADR 0002](./adr/0002-vestige-cabinet-lisptc-cortex.md) — Vestige cabinet vs lisptc cortex  
- [ADR 0003](./adr/0003-validate-before-eval.md) — Refuse malformed Lisp before session eval  
- [ADR 0004](./adr/0004-reify-replace-not-accumulate.md) — `*mind/retrieved*` replace per turn  
- [ADR 0005](./adr/0005-provider-modes.md) — Multi-provider constraint strategy  
- [ADR 0006](./adr/0006-profiles-lisp-mind-vs-pi-default.md) — Two profiles  
- [ADR 0007](./adr/0007-context-contributors.md) — Host-side context contributors (additive)  
- [ADR 0008](./adr/0008-bounded-rlm-lisp-ops.md) — Bounded RLM as optional Lisp ops (additive)  
- [ADR 0009](./adr/0009-soft-generations-and-structured-surfaces.md) — Soft generations, agendas, papercuts (additive)  

## Upstream references

| Project | Role |
|---------|------|
| [earendil-works/pi](https://github.com/earendil-works/pi) | Agent harness, `buildSystemPrompt`, extensions |
| [1hachem/lisptc](https://github.com/1hachem/lisptc) | Lisp dialect, REPL, pi extension, MCP-in-image |
| [samvallad33/vestige](https://github.com/samvallad33/vestige) | Local MCP memory (recall, smart_ingest) |
| [lambda-symbolics/autolith](https://github.com/lambda-symbolics/autolith) | Inspiration: live image, memory-context contributor (not a hard dependency) |
| [PrimeIntellect-ai/prime-agent](https://github.com/PrimeIntellect-ai/prime-agent) | Contrast: IPython RLM harness |

## Status

Planning complete in-repo. Implementation follows `plan/phase-*.md` in order.

## License

To be set by repo owner (recommended: MIT, consistent with Pi/lisptc where compatible).
