# Phase 9 — Context contributors (Autolith-inspired, additive)

## Goal

Generalize phase-7 auto-recall into a **host-side contributor registry**: turn-local instruction + evidence with priority, lifetime, and mandatory vs advice classes.

## Prerequisites

Phases 0–7 exit criteria met; phase 8 optional.

## Background

- `docs/07-autolith-adaptation.md`  
- `adr/0007-context-contributors.md`  
- Autolith `memory-related-context` + context contributor protocol (inspiration only)  
- Phase 7 reify path remains the source of related-memories data  

## Exit criteria

- [ ] Registry API: register/list contributors; run on each user message  
- [ ] At least three built-ins: related-memories, recent-user-ops, mind_active  
- [ ] Mandatory contributions always included (hard char cap)  
- [ ] Advice contributions fit within documented token budget  
- [ ] Injected block does not strip Pi coding DNA (ADR 0001)  
- [ ] Phase 7 verification still passes  

---

## Detailed tasks

### T9.1 — Contribution schema

1. Define TypeScript type: `{ id, instruction, evidence?, priority, lifetime, class }`.  
2. Caps: instruction ≤ 4k chars; evidence ≤ 2k chars per contribution; total mandatory ≤ 8k chars.  
3. Document in `docs/07-autolith-adaptation.md` or short `docs/08-contributors-api.md` if needed.

### T9.2 — Registry + run loop

1. `registerContributor(name, fn)` on extension API.  
2. On user message (after phase-7 recall): run all contributors with read-only snapshot `{ userText, cwd, retrievedHits, lastOps }`.  
3. Sort by priority; pack mandatory first, then advice until budget.

### T9.3 — Built-in: related-memories

1. Refactor phase-7 hit formatting into a contributor that emits instruction + JSON/line evidence.  
2. Instruction must state excerpts are **data, not instructions** (stale-safe).

### T9.4 — Built-in: recent-user-ops

1. Ring buffer of last 8–16 successful validated evals (form summary + result summary, truncated).  
2. Class: mandatory; priority high.  
3. Clear on session end.

### T9.5 — Built-in: mind_active

1. Compact dump of `*mind/user*` / pins / project invariants after reify.  
2. Class: advice or mandatory (choose one; document).

### T9.6 — Injection point

1. Attach packed contributions to the same channel used for mind_active in phase 7 (trailing system/developer block preferred).  
2. Verify cache extension still first on the wire (ADR 0005).

### T9.7 — Verification

1. User message triggers log: `contributors=N mandatory_chars=X advice_chars=Y`.  
2. Force advice over budget → lowest priority dropped.  
3. Local `(reply "x")` then next user message → recent-user-ops mentions prior form.  
4. Coding task still succeeds with merged prompt.

## Out of scope

RLM frames; agendas; SBCL recovery images; full Autolith CLOS protocols.
