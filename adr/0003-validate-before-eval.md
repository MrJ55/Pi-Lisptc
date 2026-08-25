# ADR 0003: Validate before session eval

## Status

Accepted

## Context

Malformed model output can corrupt REPL state. Grammar is not available on all providers. Stock lisptc may eval then reset on throw (harsh).

## Decision

1. Strip markdown fences.  
2. Parse/read (and optional GBNF check) **before** any session eval.  
3. On failure: do not eval; retry with error feedback (budget 2–3).  
4. Optional later: sandbox eval then commit.  

## Consequences

- Works with any provider.  
- Slightly more turns on weak models.  
- Image integrity preferred over speed.
