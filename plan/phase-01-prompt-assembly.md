# Phase 1 — Prompt assembly (merge + full interpreter source)

## Goal

lisp-mind uses a **merged** system prompt: Pi coding core + lisptc channel + **full interpreter source** + project context/cwd. Not stock POLICY-only replace.

## Background

- `docs/05-system-prompt-and-pi.md`  
- `adr/0001-merge-prompt-not-replace.md`  
- Pi: `packages/coding-agent/src/core/system-prompt.ts` (`buildSystemPrompt`)  
- lisptc: `apps/pi/extension/system-prompt.ts`  

## Exit criteria

- [ ] lisp-mind sessions include Pi-style coding role text  
- [ ] AGENTS.md / project_context appears when present in project  
- [ ] cwd present  
- [ ] Full interpreter source included in system prompt  
- [ ] lisptc channel rules present (Lisp-only output, halt, MCP, mind stub)  
- [ ] Verification: inspect logged system prompt or `/system` equivalent  

---

## Detailed tasks

### T1.1 — Extract Pi coding core string

1. Copy the default template logic from Pi `buildSystemPrompt` (role paragraph + guidelines structure).  
2. Store as `src/extension/prompts/pi-coding-core.ts` constant builder function `buildPiCodingCore(options)`.  
3. Map “use read/bash/edit/write” language to “use Lisp MCP bindings / in-image tools” for lisp-mind (do not list outer Pi tools if tools=[]).

### T1.2 — Lisptc channel rules module

1. Create `src/extension/prompts/lisptc-channel.ts` from lisptc POLICY, adapted:  
   - Keep: Lisp-only final output, REPL loop, halt, no fences, MCP load-mcp summary, conversation globals.  
   - Add: `(reply "…")` preferred for user text; mind epilogue placeholders (full mind in later phases).  
   - Remove contradictions if tools partially enabled.  

### T1.3 — Interpreter source

1. Import or generate `INTERPRETER_SOURCE` from lisptc package (same approach as `@repo/interpreter/source.ts`).  
2. Append to customPrompt every turn (expedient; document token cost).  

### T1.4 — before_agent_start integration

1. On `before_agent_start`, build:  
   `customPrompt = piCodingCore + "\n\n" + lisptcChannel + "\n\n" + interpreterSource`  
2. Prefer calling Pi’s `buildSystemPrompt({ customPrompt, cwd, contextFiles, skills, selectedTools: [] })` if accessible from extension API; else manually append project context files Pi would load (document how to get AGENTS paths).  
3. Return `{ systemPrompt: assembled }`.  

### T1.5 — Tools cleared

1. On `session_start`, `pi.setActiveTools([])` (mind mode).  
2. Do not register outer MCP duplicates.

### T1.6 — Verification

1. Start lisp-mind in a repo with AGENTS.md.  
2. Dump or log first 2k and last 2k chars of system prompt; confirm sections exist.  
3. Confirm interpreter source markers (known function names from dialect) appear.  

## Out of scope

Validate-before-eval, Vestige, provider mode switch (may still ship stock grammar—fix in phase 3).
