# Phase 7 — Vestige auto-recall, reify, ingest

## Goal

Implement the full bottom-line pipeline: **auto recall → reify → act → gated ingest**.

## Background

- `docs/04-mind-vestige-memory.md`  
- `adr/0002-vestige-cabinet-lisptc-cortex.md`  
- `adr/0004-reify-replace-not-accumulate.md`  
- Vestige AGENT-MEMORY-PROTOCOL (insufficient alone—host must force)  
- Autolith memory-context pattern (lexical top-k inspiration)  

## Exit criteria

- [ ] Every real user message triggers Vestige recall **without** model choosing it  
- [ ] `mind/reify!` runs with hits; `*mind/retrieved*` replaced  
- [ ] Compact mind_active injected or first lisp-output shows retrieved  
- [ ] `mind/note!` with evidence → Vestige smart_ingest (rate limited)  
- [ ] `mind/skip!` does not ingest  
- [ ] Restart: bootstrap recall rehydrates prefs/project signals  

---

## Detailed tasks

### T7.1 — Host recall helper (TypeScript)

1. Function `recallForUserMessage(text, cwd) → Hit[]`.  
2. Call Vestige via lisptc MCP bridge or direct stdio if needed.  
3. Prefer tools: `recall` or `session_context` / `search` per installed Vestige version—**detect and document**.  
4. Parse results to `{ id, text, score?, tags? }[]`; cap k=6; truncate text ~180 chars.

### T7.2 — Trigger on user message

1. On message_end or dedicated user-message hook: if role user and not custom lisp-output:  
   - hits = recallForUserMessage  
   - eval trusted `(mind/reify! :retrieved ',hits :merge-prefs t)`  
2. Build mind_active string < 2k chars; attach to next system or user context injection available in Pi API.

### T7.3 — note! → smart_ingest

1. Implement `mind/note!` in prelude to call Vestige smart_ingest with content, tags, evidence.  
2. Host rate limit: max 3 ingests per user turn.  
3. Reject empty evidence.

### T7.4 — Bootstrap on session_start

1. After MCP load: recall query = `"preferences project invariants skills " + projectName`.  
2. reify! results.

### T7.5 — Verification checklist

1. Log line: `vestige_recall hits=N` every user message.  
2. Two sequential user messages with different topics → `*mind/retrieved*` content changes (not grows unbounded).  
3. note! creates durable Vestige entry (CLI `vestige` inspect or search).  
4. New process: prefs/invariants from Vestige appear after bootstrap.

### T7.6 — Failure modes

1. Vestige down: empty hits; warn once; coding continues.  
2. Parse errors on ingest: do not crash REPL.

## Out of scope

Embedding index ownership (Vestige handles); RLM.
