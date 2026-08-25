# ADR 0008: Bounded RLM as optional Lisp operations

## Status

Proposed (phase 10 only; after measured need)

## Context

Autolith and Prime-style agents treat oversized context as an **environment**: the model decomposes work, runs bounded sub-inferences, and returns values without stuffing the entire corpus into the parent prompt. Autolith exposes `infer`, `rlm-map`, `rlm-complete` with call/token/depth budgets and content-addressed objects. Full parity is a non-goal for core Pi-Lisptc (see README non-goals).

## Decision

1. **Do not** implement RLM in phases 0–8.
2. When long-context tasks fail with phase-7 memory alone, add **optional** Lisp operations in the mind image:
   - `(mind/infer prompt &key context contract budget)` — one bounded sub-call; returns Lisp value or structured data.
   - `(mind/map prompts &key context budget)` — fan-out under shared budget.
   - Optional later: complete-style env only if isolation is available.
3. Context designators: pathname, Vestige id, string literal, or `{ :label :digest :path }` descriptor — **body stays outside** the parent model context when large.
4. Budgets are **host-enforced** (max calls, tokens, depth). Exceeding budget returns error to the parent REPL, not silent continuation.
5. Sub-frames must not pollute the parent conversation history or the main REPL bindings except via the returned value.

## Consequences

- Provider cost and latency increase when used; default coding path remains single-turn Lisp.
- Needs clear prompt policy: use RLM only for corpus-scale tasks, not routine edits.
- Aligns with phase 8 sandbox direction for isolation.
