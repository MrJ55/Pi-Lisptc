# Phase 11 — Agendas and papercuts (structured durable surfaces)

## Goal

Add thin, Vestige-backed **agenda** and **papercut** surfaces inspired by Autolith’s state separation—without a second database or sexp-store.

## Prerequisites

Phase 7 (Vestige reify + ingest) working; phase 9 optional.

## Background

- `docs/07-autolith-adaptation.md`  
- `adr/0009-soft-generations-and-structured-surfaces.md`  
- Autolith agendas / papercuts (inspiration only)  

## Exit criteria

- [ ] `*mind/agenda*` loadable from Vestige tags / bootstrap recall  
- [ ] `(mind/agenda! …)` gated write → Vestige  
- [ ] `(mind/papercut! …)` records defect with evidence; list/close ops  
- [ ] Caps: max open papercuts, max agenda items  
- [ ] Phase 7 epilogue still preferred for generic notes  

---

## Detailed tasks

### T11.1 — Agenda model

1. Structure: list of `{ id, title, status, notes, updated }`.  
2. Bootstrap: recall query includes `agenda` tag or project plan keywords.  
3. Reify merges into `*mind/agenda*` (replace list, do not unbounded append).

### T11.2 — agenda! API

1. `(mind/agenda! &key add update remove)` with evidence required for durable write.  
2. Host rate-limit shared with note! ingest budget.  
3. Reject slogan-only updates.

### T11.3 — Papercuts

1. `(mind/papercut! :title :body :evidence)` → Vestige ingest tagged `papercut`.  
2. `(mind/papercuts)` lists open; `(mind/papercut-close! id :resolution)` tombstones.  
3. Cap open papercuts (e.g. 20); oldest closed or refused when over.

### T11.4 — Prompt mention

1. Short channel note: prefer agenda/papercut for plans and defects; generic facts still `note!`.

### T11.5 — Verification

1. Add agenda item; new session bootstrap shows it after recall.  
2. Papercut create + close; closed item not in default open list.  
3. Over-cap behavior documented.

## Out of scope

Full Autolith agenda versioning UI; bug-tracker integrations; recovery generations (phase 12).
