# Risk Register

| Risk | Severity | Mitigation |
|---|---:|---|
| Generated Lisp bypasses host policy | Critical | Validate/capability-check before eval; capability-restricted runtime |
| Interpreter reset loses unrelated state | High | Checkpoints + transactional state semantics |
| Fork diverges rapidly from upstream | High | Pin baseline, divergence ledger, compatibility tests |
| Parallel provider registry | High | Pi remains sole provider/model authority |
| Duplicate MCP/jobs implementation | Medium | Reuse upstream mechanisms; add wrappers only for policy/observability |
| Unbounded recursive computation | Critical | Depth, time, token, child-count and output budgets |
| Prompt/context explosion | High | Typed contributors, quotas, deterministic allocation |
| Durable memory coupled to runtime | High | Separate Vestige policy from Lisp working state |
| Runtime snapshots become version-fragile | Medium | Versioned schema, compatibility metadata, migration tests |
| Self-modification destabilizes runtime | High | Defer; explicit artifact/reload transactions |
| Insufficient failure testing | High | Fault injection for eval, jobs, MCP, snapshots and RLM |
| Hidden provider-specific behavior | Medium | Provider-neutral host contract and integration matrix |

## Release blockers

The following should block a production-oriented milestone:

1. capability bypass;
2. nondeterministic rollback/state corruption;
3. unbounded resource consumption;
4. inability to cancel external/recursive work;
5. multiple competing authorities for model/provider or durable memory state.
