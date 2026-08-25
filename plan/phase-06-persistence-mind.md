# Phase 6 — Persistence and mind hygiene

## Goal

Prelude loads on session start; pins/prefs can persist; promote skills to disk.

## Background

- `docs/04-mind-vestige-memory.md`  
- `adr/0004-reify-replace-not-accumulate.md`  

## Exit criteria

- [ ] `src/prelude/*.lisp` loaded at session_start before model acts  
- [ ] mind API stubs exist: reify!, note!, skip!, prefer! (full Vestige wiring in phase 7)  
- [ ] Caps constants defined (max pins, max skills)  
- [ ] Optional save/load of prefs file under XDG or `.lisptc/`  

---

## Detailed tasks

### T6.1 — Prelude files

1. Create `src/prelude/mind-api.lisp` with:  
   - `*mind/retrieved*`, `*mind/user*`, `*mind/ux*`, `*mind/pins*`  
   - `(mind/reify! &key retrieved merge-prefs)` **REPLACE** retrieved  
   - `(mind/skip! &key reason)`  
   - stubs for note!/prefer! that only update local pins until phase 7  

### T6.2 — Load order

1. session_start: reset or new AgentRepl → load all prelude files in sorted order → mcp bootstrap (phase 4).

### T6.3 — Caps

1. `*mind/max-pins* = 40`, max skill register 30.  
2. Evict oldest pin when over cap.

### T6.4 — Disk prefs (optional but recommended)

1. Save `*mind/user*` to `.lisptc/user-prefs.sexp` on change.  
2. Load on start.

### T6.5 — Verification

1. Set pref in session; restart lisp-mind; pref restored if disk enabled.  
2. reify! twice with different lists; only second list in `*mind/retrieved*`.

## Out of scope

Vestige auto-recall (phase 7).
