# Vestige recall and REPL reification clarification

## Decision

For the living-mind design, relevant Vestige results must be reified into the persistent Lisptc REPL before the mind acts. Prompt-level recall is supplementary; it is not the primary memory mechanism.

The Pi extension host performs retrieval, ranking, validation, safe serialization, and controlled evaluation of a trusted reification operation in the active session.

## Per-turn flow

```text
Pi receives a turn
  -> host builds Pi coding context
  -> host queries Vestige by scope/relevance/freshness/pins/sensitivity
  -> host selects bounded top-k
  -> host serializes selected records as data-only Lisp literals
  -> host validates an allowlisted reification form
  -> persistent Lisptc REPL evaluates it
  -> model evaluates Lisp actions against living session state
  -> Lisp reaches tools through Lisptc MCP
  -> epilogue proposes learning candidates
  -> gated smart_ingest optionally updates durable Vestige
  -> next turn replaces the previous transient recall set
```

## Memory strata

```text
Persistent session REPL
- definitions, macros, loaded skills
- ephemeral working state
- explicitly pinned items, within a hard cap

Per-turn reified recall
- top-k task-relevant Vestige records
- replaced at every turn, never blindly accumulated

Durable Vestige
- canonical facts, decisions, skills, summaries, and provenance
- queried selectively; never dumped wholesale into prompt or REPL
```

## Safe reification contract

Vestige content must never become arbitrary executable Lisp. The host constructs a data-only literal passed to a preinstalled trusted prelude function:

```lisp
(mind.replace-turn-recall
  '(:turn-id "turn-0042"
    :items
    ((:id "ves_001"
      :kind :project-fact
      :text "The repository uses pnpm workspaces."
      :scope :workspace
      :confidence 0.94
      :source (:kind :file :path "pnpm-workspace.yaml")
      :tags ("build" "tooling")))))
```

The prelude maintains structured session data, for example `*mind-turn-recall*` plus an index. The action program uses explicit APIs:

```lisp
(mind.recall-all)
(mind.recall-by-tag "architecture")
(mind.recall-by-kind :decision)
(mind.recall-get "ves_001")
(mind.recall-search "MCP action policy")
```

## Replace, not accumulate

At turn start, `mind.replace-turn-recall` must:

1. Clear the previous transient recall set/index.
2. Install the newly selected top-k records.
3. Preserve only explicitly pinned session items within a hard cap.
4. Record selected IDs, retrieval query, ranking/version, and digest in the audit manifest.
5. Expose inspectable recall state to Lisp and host diagnostics.

This preserves a living session without stale, duplicated, or unbounded memory.

## Safety pipeline

```text
Vestige record
  -> schema validation
  -> scope/sensitivity filtering
  -> relevance ranking and item/token budget
  -> data-only Lisp serializer
  -> parse to Lisp AST
  -> allowlist validation: only (mind.replace-turn-recall <quoted-literal>)
  -> evaluate in active session
```

Never evaluate a memory text field directly, for example `repl.eval(record.text)`. Text is a string inside a quoted data literal, not executable syntax.

## Write-side learning

At turn end, the session and trace may produce candidate facts/skills. `smart_ingest` validates, deduplicates, scopes, gates, and persists approved candidates as durable Vestige events. Future turns retrieve and reify only relevant top-k records. This is the complement to start-of-turn hydration.

## Related review documents

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Interfaces and invariants](INTERFACES-AND-INVARIANTS.md)
- [Test strategy](TEST-STRATEGY.md)
- [Pi extension-host clarification](PI-EXTENSION-HOST-CLARIFICATION.md)
