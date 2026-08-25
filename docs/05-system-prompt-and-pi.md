# System prompt: Pi vs lisptc vs merge

## Pi default (`buildSystemPrompt`)

Source: `packages/coding-agent/src/core/system-prompt.ts` in earendil-works/pi.

- Role: expert coding assistant in pi; read, execute, edit, write.  
- Available tools list from selected tools + snippets.  
- Guidelines: tool-dependent exploration tips; always concise; show file paths.  
- Pi docs index for self-modification of the harness.  
- Append section, `<project_context>` from AGENTS.md, skills (if read available), cwd.  

When `customPrompt` is set, builder still appends project context, skills (if read), cwd.

## Stock lisptc

Source: `apps/pi/extension/system-prompt.ts` + `lisp-repl.ts`.

- POLICY: Lisp machine, not chat; output only Lisp; no tools; REPL loop; halt; MCP load-mcp; conversation globals; no comments; thinking ≠ Lisp.  
- `before_agent_start` → `{ systemPrompt: SYSTEM_PROMPT }` (**replace**).  
- `setActiveTools([])`.  
- Grammar injection on provider request (Fireworks-oriented).  

`SYSTEM_PROMPT` may be POLICY only on some revisions; comments intend POLICY + interpreter source—**this project always includes full source in merged prompt (phase 1 expedient).**

## Merge strategy (this project)

```text
customPrompt =
  [Pi coding core — role, concise, paths, explore→edit→verify mapped to Lisp/MCP]
  + [lisptc channel — Lisp-only output, loop, halt/reply, MCP-in-image, mind rules]
  + [INTERPRETER_SOURCE full]
  + buildSystemPrompt attachments: project_context, cwd, optional append
```

## User-facing channel

- Prefer `(reply "…")` / `(halt …)` for humans.  
- Host pretty-prints structured values.  
- Do not require a second “translator” agent by default.
