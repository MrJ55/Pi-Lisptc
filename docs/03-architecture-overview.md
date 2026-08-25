# Architecture overview

## Runtime components

```text
┌──────────────────────────────────────────────────────────┐
│ Pi coding agent (TUI, sessions, providers, extensions)   │
│  - opencode-go-cache (before_provider_request)           │
│  - pi-lisptc extension (this project)                    │
└────────────┬─────────────────────────────┬───────────────┘
             │                             │
             ▼                             ▼
    Provider HTTP/SSE              lisptc AgentRepl (in-process)
    (grammar | retry | tool)       + prelude mind API
             │                             │
             │                             ├─ MCP: Vestige
             │                             ├─ MCP: filesystem / etc.
             │                             └─ *mind/* bindings
             ▼
        Model tokens
```

## Profiles

| Profile | System prompt | Tools | Mind loop |
|---------|---------------|-------|-----------|
| `pi-default` | Pi default assembly | Default + extension tools | Off |
| `lisp-mind` | Merged Pi coding + lisptc channel + interpreter source + project context | `[]` or minimal | On |

## Turn pipeline (lisp-mind)

1. User message arrives.  
2. Host: Vestige recall(query=user text, scope=project).  
3. Host: eval trusted `(mind/reify! :retrieved hits)` — **replaces** `*mind/retrieved*`.  
4. Host: inject compact `mind_active` into next model context.  
5. Model returns Lisp (constrained or soft).  
6. Host: strip fences → **validate/parse** → on fail retry (no session eval).  
7. Host: session eval; MCP calls as Lisp.  
8. Host: render `(reply)` / `(halt)` / pretty-print; apply UX prefs.  
9. Host: epilogue `mind/note!` → Vestige `smart_ingest` (gated) or `mind/skip!`.

## Prompt assembly (lisp-mind)

Use Pi’s `buildSystemPrompt` contract when possible:

- `customPrompt` = Pi coding core + lisptc channel rules + **full INTERPRETER_SOURCE** (expedient)  
- `contextFiles` = AGENTS.md layers  
- `skills` if still applicable  
- `cwd`  

Do **not** only `return { systemPrompt: POLICY }` without project context.

## Wire constraints

Order on `before_provider_request`:

1. Cache stamps (`opencode-go-cache`)  
2. Constraint: grammar **or** leave plain for retry mode  

Never strip cache fields when adding `response_format`.
