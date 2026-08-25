# ADR 0004: Reify replaces turn retrieval; do not bloat REPL

## Status

Accepted

## Context

If each Vestige recall appends to the image, the REPL grows without bound and becomes another dump.

## Decision

- `*mind/retrieved*` is **replaced** every user-turn recall.  
- Prefs: small key merge only.  
- Pins/lessons: capped ring; short text + id.  
- Skills: capped; promote deliberately.  
- Durable bulk remains in Vestige only.  

## Consequences

- Implementers must not `append` retrieved lists across turns.  
- Session serialize must not dump full recall history.
