# Test strategy and release gates

## Principle

First inherit Lisptc interpreter confidence; then test Pi policy as explicit contracts. Preserve the existing upstream test taxonomy: reader, grammar, numeric/string/list behavior, macros, recursion/control flow, errors, imports, source/prelude, secrets, MCP, OAuth, printing, and fixtures.

## Test pyramid

| Level | Focus | Examples |
|---|---|---|
| Unit | Pure schema/order/policy/budget logic | invalid profile; stable sort; expired memory; denied grant; exhausted budget |
| Contract | Prelude-host-adapter boundary | Lisp request -> typed result; normalized provider result; MCP schema validation |
| Integration | Full controlled turn | profile -> manifest -> provider fixture -> tool fixture -> ledger |
| Differential | Fork vs pinned Lisptc | unchanged upstream suites; Pi enabled/disabled semantic comparison |
| Adversarial | Untrusted/recursive/failing inputs | secret/oversized contributor; denied MCP; interrupted materialization; nested RLM |
| E2E | User observable behavior | inspect context; cancel; no-side-effect trace replay |

## Baseline compatibility

Run pinned Lisptc tests unchanged before Pi features enable. Maintain a status matrix for reader, macros, MCP, secrets, and prelude. Every intended mismatch needs `FORK-DELTA.md`, a dedicated test, rationale, and migration note.

## Required context fixtures

- Same inputs/profile/contributor versions produce same digest.
- Order survives different contributor execution order.
- Over-budget candidates record deterministic omission reasons.
- Sensitivity policy acts before render.
- Contributor failure cannot remove required system context.
- Expired/superseded materializations are excluded.
- Diagnostics redact secrets.

## Required capability/MCP fixtures

- Unknown capability/operation/server/tool/profile is denied.
- Ungranted valid request is denied before adapter connection.
- Granted call produces linked request/decision/result events.
- Credentials are referenced, not serialized.
- Timeout/cancellation has one coherent terminal result.
- Tool output is size limited and revalidated as untrusted before context reuse.

## Required persistence/reification fixtures

- Event schema round-trip/migration.
- Input digests and generator version persistence.
- Idempotent identical materialization.
- One active artifact per replacement key.
- Interrupted writes never expose partial active artifact.
- Redaction/deletion invalidates future derived artifacts according to policy.
- Provenance traces injected vestiges without unauthorized disclosure.

## Required RLM fixtures

Test depth, elapsed time, model/tool counters, tokens, cost, and parallel aggregate budget; parent-to-child cancellation; cycle handling; and prevention of successful commits after cancellation.

## CI

Each PR: formatting/types/lint/unit, upstream compatibility, changed-boundary contracts, secret scan, persisted-schema tests.

Release candidate: provider/MCP/store fixtures, adversarial policy/redaction/budget tests, migration/rollback rehearsal, no-side-effect replay, and manual review of new capabilities/grants.

Retain redacted versioned fixtures only; do not retain production secrets or raw sensitive context.