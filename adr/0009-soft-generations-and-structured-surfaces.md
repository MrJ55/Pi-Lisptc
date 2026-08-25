# ADR 0009: Soft generations and structured durable surfaces

## Status

Proposed (phases 11–12)

## Context

Autolith separates durable surfaces (conversations, memories, agendas, papercuts) and supports **generations** / recovery images after destructive self-modification. Pi-Lisptc uses Vestige as the cabinet and the lisptc REPL as cortex. Full SBCL core snapshots and `self.*` agent surgery are out of scope.

## Decision

1. **Agendas** (optional): versioned workspace plan as `*mind/agenda*` plus Vestige-backed entries tagged `agenda`. Host helpers load/save; model updates via gated `mind/agenda!`.
2. **Papercuts** (optional): user-visible defects recorded with evidence via `mind/papercut!` → Vestige; close with tombstone metadata. Not a second bug tracker—thin durable notes.
3. **Soft generations** (optional): on session_start or explicit `(mind/snapshot!)`, persist prelude + pins + prefs to a dated snapshot under project or XDG data. Restore is load-into-REPL, not process reboot into a recovery core.
4. Reject Autolith-style private mutation repos and recovery-image boot loops inside this extension.

## Consequences

- Gives structured evolution beyond free-form `note!` without adopting Autolith’s full state taxonomy.
- Snapshot/restore is best-effort continuity, not crash-proof agent OS semantics.
- Keeps cabinet = Vestige; does not invent a parallel sexp-store.
