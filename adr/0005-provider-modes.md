# ADR 0005: Provider modes grammar | json-tool | retry

## Status

Accepted

## Context

Fireworks supports GBNF; many providers do not. Unconditional grammar breaks non-Fireworks routes.

## Decision

Select mode per provider/model capability. Compose with cache extension (cache mutations first). Always host-validate before eval regardless of mode.

## Consequences

- Capability registry needed (simple table OK for v1).  
- Retry path is first-class, not a fallback afterthought.
