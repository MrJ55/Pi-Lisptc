# ADR 0006: Two profiles — lisp-mind vs pi-default

## Status

Accepted

## Context

Users need classic Pi (extensions as tools, default prompt) and mind mode without permanent breakage.

## Decision

- **pi-default**: no lisptc mind loop; normal tools; opencode-go-cache OK.  
- **lisp-mind**: merged prompt; tools empty/minimal; MCP-in-image; reify loop.  

Launch via scripts/aliases or Pi settings profiles.

## Consequences

- Document both clearly in README and scripts.  
- Do not half-enable 50 outer MCP tools under Lisp-only prompt.
