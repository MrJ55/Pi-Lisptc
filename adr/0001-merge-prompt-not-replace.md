# ADR 0001: Merge Pi system prompt; do not stock-replace

## Status

Accepted

## Context

Upstream lisptc returns `{ systemPrompt: SYSTEM_PROMPT }` and clears tools. Pi coding performance depends on default prompt DNA (role, tools guidance, guidelines, AGENTS.md, cwd). Goal is enhance Pi with lisptc, not eliminate Pi abilities.

## Decision

In `lisp-mind` profile, assemble prompt via Pi’s `buildSystemPrompt` (or equivalent) with:

- customPrompt = Pi coding core + lisptc channel + full interpreter source  
- Always attach project context and cwd  

Never ship a lisp-mind mode that only sets POLICY without project context.

## Consequences

- Larger system prompt; mitigate with cache and large context.  
- Must rewrite stock lisptc `before_agent_start` behavior in this project’s extension.  
- `pi-default` profile remains stock Pi.
