# Phase 10 — Bounded RLM Lisp ops (optional, measured need)

## Goal

Add optional **bounded recursive inference** as Lisp operations so large corpora stay outside the parent prompt, without adopting Autolith/Prime as the primary agent.

## Prerequisites

Phases 0–7 daily-stable; phase 9 recommended; **documented failure** of long-context tasks with phase-7 memory alone.

## Background

- `docs/07-autolith-adaptation.md`  
- `adr/0008-bounded-rlm-lisp-ops.md`  
- Autolith `docs/rlm.org` (inspiration)  
- Phase 8 sandbox eval (if present) for isolation  

## Exit criteria

- [ ] `(mind/infer …)` returns a Lisp value under call/token/depth budget  
- [ ] Context designators: string | path | Vestige id | descriptor `{label,digest,path}`  
- [ ] Parent conversation not polluted by sub-frame messages  
- [ ] Budget exhaustion returns error value, does not hang  
- [ ] Default coding path unchanged when RLM unused  
- [ ] Cost/latency notes in VERIFY-LOG  

---

## Detailed tasks

### T10.1 — Budget object

1. Lisp or host struct: `calls`, `tokens`, `depth` with defaults (e.g. 8 / 40k / 2).  
2. Host decrements on each sub-provider call; refuse when zero.

### T10.2 — Context materialization

1. Resolve designator → content bytes or stream.  
2. If size > threshold (e.g. 32k chars), store under content-addressed path or Vestige blob; pass **descriptor only** to parent model.  
3. Sub-frame may request slices by offset/query (minimal: whole-or-nothing first).

### T10.3 — `mind/infer`

1. Signature: `(mind/infer prompt &key context contract budget)`.  
2. Host opens isolated sub-request (no parent tool list pollution).  
3. Optional JSON-schema-like contract → validate return before reifying into parent REPL.  
4. On success: return Lisp data; on failure: `(:error …)`.

### T10.4 — `mind/map` (optional same phase)

1. Fan-out list of prompts under **shared** budget.  
2. Collect results as list; stop when budget hits zero.

### T10.5 — Prompt policy snippet

1. Add short POLICY section: use infer/map only for corpus-scale analysis; routine edits stay single-turn.  
2. Do not replace Pi coding DNA.

### T10.6 — Verification

1. Infer over a file larger than small context limit → parent prompt contains digest not full body.  
2. Budget 1 call → second nested infer errors cleanly.  
3. Normal `(reply …)` coding turn with RLM unused → token profile comparable to phase 7.

## Out of scope

Full `rlm-complete` isolated heap env; Autolith resource URI scheme; Prime Continual Harness; unbounded recursion.
