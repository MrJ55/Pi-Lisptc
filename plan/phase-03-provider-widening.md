# Phase 3 — Provider widening

## Goal

lisp-mind works on Fireworks (grammar) and at least one non-grammar provider (retry). Coexist with opencode-go-cache.

## Background

- `docs/06-provider-constraints.md`  
- `adr/0005-provider-modes.md`  
- Fireworks grammar docs; lisptc `before_provider_request` grammar stamp  

## Exit criteria

- [ ] Capability table: provider → mode  
- [ ] Grammar only when supported  
- [ ] Retry mode does not send invalid response_format  
- [ ] Cache fields still present when both extensions active  
- [ ] Manual test on two providers  

---

## Detailed tasks

### T3.1 — Capability registry

1. Create `src/extension/providers/capabilities.ts`:  
   `{ fireworks: { grammar: true }, "opencode-go": { grammar: false }, default: { grammar: false } }`  
2. Resolve from `event` model/provider id in before_provider_request.

### T3.2 — Conditional grammar

1. Replace unconditional grammar assignment.  
2. If grammar: set `response_format: { type: "grammar", grammar: LISP_GRAMMAR }`.  
3. Else: do not set grammar response_format.

### T3.3 — Cache composition

1. Document load order: cache extension registered; runs before or after—**test** both.  
2. If this extension overwrites entire payload, **merge** preserve `prompt_cache_key`, `cache_control`, retention fields.  
3. Add regression test: mock payload with cache fields → after constraint, fields remain.

### T3.4 — Retry UX

1. Ensure phase 2 errors tell the model “output only Lisp dialect forms”.  
2. Optional: append soft reminder message every N failures.

### T3.5 — Verification

1. Fireworks model: grammar path; valid Lisp.  
2. Non-grammar provider: invalid then valid turn.  
3. Inspect outbound request JSON for cache + grammar combo on Fireworks.

## Out of scope

Full shared constraint-adapter package (can live in this extension first).
