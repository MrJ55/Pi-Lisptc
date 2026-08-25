# Mind, Vestige, and reification

## Cabinet vs cortex

| | Vestige | lisptc image |
|--|---------|--------------|
| Role | Durable associative memory | Working cortex |
| Storage | SQLite (local) | Process heap (+ prelude files) |
| Retrieval | Hybrid keyword/semantic, FSRS, graph | Bindings, `defun` |
| Writes | `smart_ingest`, promote/demote | `setq`, `defun`, pins |

Using Vestige **does not** invalidate the self-modifying mind. **Failing to reify** recall into the image does.

## Forced use (not optional tools)

Vestige’s agent protocol text (“call session_context…”) is **insufficient** alone. Host must:

1. Auto-call recall each user turn.  
2. Reify into `*mind/retrieved*` (and merge prefs).  
3. Inject summary and/or gate first forms.

## Reify: replace, do not accumulate

```lisp
(setq *mind/retrieved* hits)   ; REPLACE each turn
```

- Size ≈ top-k excerpts (e.g. k=6, ~2k chars total evidence).  
- **Pins / lessons**: optional, **capped** ring.  
- **Prefs**: small key/value merge only.  
- **Skills**: promote rarely to `defun` + prelude disk.  
- Full history stays in Vestige, not the REPL.

## Mind namespaces (session)

```text
*mind/retrieved*   ; turn working set (replaced)
*mind/user*        ; prefs
*mind/ux*          ; presentation
*mind/project*     ; invariants (pinned)
*mind/pins*        ; capped short lessons
*mind/skills*      ; registered callables metadata
```

## Epilogue (evolution without noise)

Each productive turn ends with:

- `(mind/note! …)` / `(mind/prefer! …)` / `(mind/fail! …)` with **evidence**, or  
- `(mind/skip! :reason "…")`

Host maps note/prefer/fail → `smart_ingest` with rate limits; rejects slogans and dumps.

## Autolith inspiration

`memory-related-context`: tokenize user text, drop stopwords, `memory-rank`, top 6, inject as turn context contributor. Port **behavior**, not full Autolith resource stack.
