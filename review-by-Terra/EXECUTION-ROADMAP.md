# Revised execution roadmap

## Rule

Every phase produces a testable artifact and measurable exit gate. Later phases do not compensate for unclear earlier contracts.

## 0. Upstream baseline and fork contract

Deliver: pinned `UPSTREAM.md`; `FORK-DELTA.md`; clean-environment reproducibility; unchanged Lisptc interpreter test CI; compatibility corpus for reader, macros, imports, errors, prelude/source, secrets, MCP, and OAuth.

Gate: baseline and upstream tests pass with Pi features disabled; any divergence blocks merge unless documented and tested.

## 1. Profile and context kernel

Deliver: versioned profile schema; `ContextCandidate`; manifest/renderer; token-budget policy; static-system and explicit-user contributors only; `--explain-context` diagnostics.

Gate: identical inputs/profile/configuration yield identical manifest and digest; invalid/over-budget candidates yield typed outcomes; only assembler may write final context.

## 2. Input and image boundary

Deliver: typed input envelope; media MIME/size/dimension/decode policy; sensitivity/redaction classification.

Gate: malformed/disallowed media cannot reach provider or persistence; negative fixtures include corrupt, oversized, mismatched, and denied-profile input.

## 3. Provider adapter contract

Deliver: neutral request/result/error/cancellation/usage types; matrix for streaming, tools, structured outputs, vision, grammar, context capacity, cancellation; per-profile fallback rules.

Gate: provider swap changes adapter/config only; normalized results cross host/prelude boundary; usage reaches ledger when available.

## 4. Capability host and MCP bootstrap

Deliver: registry; operation schemas; grants; budgets; audit; MCP server/tool allowlists; credential references; fixture adapters.

Gate: every invocation has validated request, grant, decision, budget record, and terminal event; denied calls do not connect; secrets never enter manifest/logs.

## 5. User channel and trace UX

Deliver: turn/profile/context digest/capability/provider usage/outcome state; inspect-effective-context and cancel/revoke controls; redacted machine-readable trace export.

Gate: no-side-effect turn can replay from manifest/fixtures; trace redaction is tested.

## 6. Durable event store

Deliver: append-only event schema/migrations; scope/retention/deletion/redaction/ownership policy; provenance-returning query API with no implicit injection.

Gate: derived state rebuilds from events; deletion/redaction behavior affects future materialization as specified; durable persistence initially opt-in by profile/workspace.

## 7. Vestige/reification materializer

Deliver: materialization manifest with source digests, replacement key, versions/status/time; atomic replacement/rollback/expiry/invalidation; review mode for high-privilege effects.

Gate: identical input is idempotent; one active artifact per key; every injection traces to source events and generator version.

## 8. Operational hardening

Deliver: migrations/backups/restore; error taxonomy; cancellation; telemetry policy; provider/MCP/store/materializer failure injection.

Gate: failures create no untraceable partial state; interrupted writes and stale locks recover in tests.

## 9. External contributors

Deliver: contributor SDK/schema, version negotiation, isolation/trust/budget model, deterministic ordering, test harness.

Gate: faulty contributor cannot read secrets, exceed budget, or corrupt final context; provenance is manifest-visible.

## 10. Bounded RLM

Deliver: enforced depth/time/model/tool/token/cost/generated-byte/side-effect counters; parent-child trace graph; cancellation and loop policy.

Gate: all limits are adversarially tested; cancellation leaves coherent audit and no committed partial materialization.

## 11--12. UX and soft generations

Agenda/papercut and soft-generation work must consume structured state, declare provenance, stay non-authoritative, and never bypass capability/materialization policy.

## Cross-cutting release gates

1. Contract and negative-path tests
2. Interpreter-host integration tests
3. Trace/observability coverage
4. Migration/rollback documentation for persistent changes
5. Security review for every new side-effecting capability