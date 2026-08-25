# Phase 4 — MCP bootstrap (in-image)

## Goal

Load MCP servers inside lisptc (Vestige, filesystem). Outer Pi tool list stays empty. Model uses Lisp bindings.

## Background

- `docs/03-architecture-overview.md`  
- lisptc POLICY section on `load-mcp`  
- Hermes pattern: tools as native Lisp functions; unwrap JSON results  

## Exit criteria

- [ ] Prelude or session_start loads configured MCP servers  
- [ ] `(list-tools)` or equivalent shows Vestige/fs tools after await  
- [ ] No duplicate outer Pi MCP schemas for those servers in lisp-mind  
- [ ] Result unwrapping works for Vestige tool results (Lisp data, not opaque strings)  

---

## Detailed tasks

### T4.1 — Config file

1. Create `src/prelude/mcp-bootstrap.lisp` or JSON config listing servers:  
   - vestige: command `vestige-mcp`  
   - fs: npx filesystem server with workspace path  

### T4.2 — Auto load on session_start

1. After REPL init, host evals trusted:  
   `(await-all (list (load-mcp …vestige…) (load-mcp …fs…)))`  
2. Handle failure gracefully (notify user; continue).

### T4.3 — Unwrap tool results

1. Inspect lisptc MCP layer; if JSON returns as string, implement unwrap (parse single text content JSON → Lisp structure).  
2. Add test with mock tool result.

### T4.4 — Verification

1. In lisp-mind, after start, eval `! (list-tools)` or model form listing tools.  
2. Call a read-only Vestige status/search with empty/safe query.  
3. Confirm outer `setActiveTools([])` still holds.

## Out of scope

Full auto-reify loop (phase 7); only load MCP.
