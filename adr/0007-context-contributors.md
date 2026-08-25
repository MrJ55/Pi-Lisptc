# ADR 0007: Host-side context contributors (Autolith-inspired)

## Status

Proposed (post phase 0–8)

## Context

Autolith injects request-local context via **contributors**: functions over a read-only request snapshot that return zero or more contributions (instruction, optional evidence, priority, lifetime, class). Related memories are one built-in contributor. Phase 7 already forces Vestige recall + reify; a general contributor registry extends that pattern without requiring the model to opt in.

## Decision

1. After phases 0–8 are stable, add a **host-side contributor registry** in the Pi-Lisptc extension.
2. Each contributor returns structured contributions:
   - `id`, `instruction` (trusted), optional `evidence` (untrusted excerpts),
   - `priority`, `lifetime` (`:turn` | `:next-request` | `:while-relevant`),
   - `class` (`:mandatory` | `:advice`).
3. **Mandatory** contributions always attach (subject to hard char cap). **Advice** competes for a small token budget (~1.5k tokens default).
4. Built-in contributors (minimum):
   - related-memories (phase 7 path, re-framed as contributor),
   - recent-user-ops (last N validated Lisp results),
   - mind_active summary from reify.
5. Do **not** port Autolith’s full CLOS contributor machinery or sexp-store; keep TypeScript/host + thin Lisp hooks.

## Consequences

- Extends phase 7 without rewriting its exit criteria.
- Requires injection point in Pi prompt assembly (developer/system trailing block or user-context field).
- Advice budget prevents contributor spam from drowning coding DNA (ADR 0001).
