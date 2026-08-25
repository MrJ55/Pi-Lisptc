# Phase 2 — Image safety (validate before eval)

## Goal

Malformed assistant output never mutates the session REPL. Retry with feedback.

## Background

- `docs/06-provider-constraints.md`  
- `adr/0003-validate-before-eval.md`  
- lisptc `lisp-repl.ts` `message_end` / `evalCode` / `stripFences`  

## Exit criteria

- [ ] Parse failure → no `repl.eval` on session  
- [ ] Model receives structured error and may retry within budget  
- [ ] After budget exhausted, user-visible failure; image unchanged  
- [ ] Unexpected host throw policy documented (prefer no blind full reset, or reset only sandbox)  

---

## Detailed tasks

### T2.1 — stripFences

1. Port/keep `stripFences` from lisptc.  
2. Unit test: plain Lisp; fenced ```lisp; fenced ```; nested edge cases.

### T2.2 — validateForm(code) → { ok, error }

1. Use lisptc reader/parser if exported; else try catch on dry-run parse API.  
2. Optional: load `LISP_GRAMMAR` / checker if available without provider.  
3. Return clear error string (line if possible).

### T2.3 — message_end pipeline change

1. On assistant message: extract text parts only (exclude thinking).  
2. stripFences → validateForm.  
3. If !ok: inject lisp-output error JSON; increment retryCount; if retryCount < MAX (2–3), trigger continue; else stop. **Do not eval.**  
4. If ok: eval as today; reset retryCount on success.

### T2.4 — Soften reset-on-throw

1. Review stock `evalCode` that resets entire interpreter on throw.  
2. Prefer: mark error, keep definitions unless corruption detected.  
3. Document choice in code comment.

### T2.5 — Verification

1. Force model or inject assistant text `Hello` → must not define bindings; error output.  
2. Valid `( + 1 2)` → eval 3.  
3. Confirm retry at most MAX times.

## Out of scope

Sandbox worker process (phase 8).
