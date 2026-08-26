# Terra independent review index

This index links the original independent review and the subsequent implementation clarifications.

## Core review

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Execution roadmap](EXECUTION-ROADMAP.md)
- [Interfaces and invariants](INTERFACES-AND-INVARIANTS.md)
- [Test strategy](TEST-STRATEGY.md)
- [ADR recommendations](ADR-RECOMMENDATIONS.md)

## Clarifications

- [Pi extension-host clarification](PI-EXTENSION-HOST-CLARIFICATION.md): locates the host primarily in the expanded `apps/pi` extension, explains preservation of Pi coding context, and defines the forced Lisp/MCP action channel.
- [Vestige reification clarification](VESTIGE-REIFICATION-CLARIFICATION.md): defines start-of-turn top-k retrieval and safe reification into the persistent REPL, replace-not-accumulate semantics, and gated write-side learning.

## Reading order

Read the Pi extension-host clarification first for G1/G2, then Vestige reification for G3/G4/G8. The core review documents remain the normative architecture, roadmap, interfaces, test gates, and proposed ADR set.
