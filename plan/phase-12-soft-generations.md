# Phase 12 — Soft generations and recovery mindset

## Goal

Provide **best-effort** session snapshots of mind state (prelude, pins, prefs) so a corrupted REPL can be restored without Autolith recovery cores or process reboot into a pristine image.

## Prerequisites

Phase 6 persistence; phase 7 optional. Phase 8 sandbox recommended.

## Background

- `docs/07-autolith-adaptation.md`  
- `adr/0009-soft-generations-and-structured-surfaces.md`  
- Autolith generations / recovery image (inspiration only; **not** ported)  

## Exit criteria

- [ ] `(mind/snapshot! &optional label)` writes dated snapshot under XDG or `.lisptc/snapshots/`  
- [ ] `(mind/restore! id)` loads bindings into current REPL (or documents restart+load path)  
- [ ] List snapshots; keep last N (e.g. 10)  
- [ ] Snapshot never includes secrets/credentials  
- [ ] Document: this is continuity, not crash-proof agent OS  

---

## Detailed tasks

### T12.1 — Snapshot contents

1. Serialize: `*mind/user*`, `*mind/pins*`, `*mind/project*`, registered skill metadata, optional agenda.  
2. Exclude: full `*mind/retrieved*` (turn-local), raw provider tokens, env secrets.  
3. Format: sexp or JSON; human-readable preferred.

### T12.2 — Snapshot / restore API

1. Host implements file write under project-safe or XDG path.  
2. `restore!` evals or sets bindings; does not replace process image.  
3. Optional: auto-snapshot on session_end if dirty.

### T12.3 — Lobotomy mitigation

1. If phase 8 sandbox exists: prefer commit-defs-on-success before snapshot.  
2. Document manual path: restart lisp-mind + restore last good snapshot.

### T12.4 — Verification

1. Mutate pins → snapshot → clear pins → restore → pins match.  
2. Snapshot dir respects retention cap.  
3. No API keys in snapshot files (grep test).

## Out of scope

SBCL core dumps; private mutation Git repos; automatic recovery-image boot; `self.*` agent surgery.
