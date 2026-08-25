# Phase 5 — User channel (reply / halt / pretty-print)

## Goal

Humans see readable output via `(reply)` / `(halt)` and host formatting of structured values.

## Background

- Thread: options A (reply convention) + B (host pretty-print)  
- lisptc `(halt)` already ends loop  

## Exit criteria

- [ ] `(reply "hello")` shows `hello` to user without requiring raw S-expr reading  
- [ ] `(halt "done")` ends loop and shows message  
- [ ] Structured list/alist values pretty-printed as bullets when not reply  
- [ ] Prompt documents reply/halt  

---

## Detailed tasks

### T5.1 — Detect reply/halt in eval result path

1. After eval, if last form is reply/halt special, extract string.  
2. Display via pi notify or custom message display path.  

### T5.2 — Pretty-printer

1. Implement `formatValue(lispValue) → string` for lists of strings, alists with :title/:bullets.  
2. Hook when result is not reply string.

### T5.3 — Prompt update

1. Add to lisptc-channel.ts: final user text must use reply/halt; data for host print OK.

### T5.4 — Verification

1. Eval `(reply "test-visible")` → user sees test-visible.  
2. Eval `'((:title "A") (:bullets ("x" "y")))` → formatted.  

## Out of scope

LLM narrator subagent.
