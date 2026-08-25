# ADR 0002: Vestige is cabinet; lisptc image is cortex

## Status

Accepted

## Context

Durable associative memory (Vestige) and live self-modifying REPL state solve different problems. Optional MCP memory without reification is a filing cabinet.

## Decision

- Vestige: durable store; host auto-recall; smart_ingest for gated writes.  
- lisptc image: working mind; reify recall into bindings; skills as `defun`.  
- Bridge: recall → **reify** → act → ingest/promote.  

## Consequences

- Must implement host bootstrap; cannot rely on Vestige prompt protocol alone.  
- Cortex continuity across processes = prelude disk + rehydrate from Vestige.
