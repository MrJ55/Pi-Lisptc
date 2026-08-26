# Roadmap Critique and Revised Execution Plan

## Assessment of the current phases

### Phase 0 — Baseline & profiles
**Keep. Make stronger.**

The two-profile strategy is essential. Add explicit regression evidence that `pi-default` is behaviorally unchanged: prompt, tools, provider request, session persistence and normal coding flow.

Add:

- profile resolution contract;
- clean session lifecycle;
- telemetry correlation ID;
- baseline token/context measurement.

### Phase 1 — Prompt assembly
**Keep, but add runtime contract first.**

The upstream source proves that the stock extension returns only its Lisp policy from `before_agent_start`, losing Pi's normal prompt assembly. The fork should not repeat that architecture.

Change T1.4 from “prefer calling buildSystemPrompt if accessible” to:

> Treat Pi's prompt builder as the authoritative integration contract; use it if the extension API exposes it, and otherwise create a narrowly documented compatibility adapter with tests against the expected Pi sections.

Do not duplicate the whole Pi prompt implementation without pinning the Pi version/API assumption.

### Phase 2 — Image safety
**Promote to mandatory release gate.**

The upstream `message_end` directly calls `repl.eval()` and resets the whole interpreter on exceptions. The fork's parse-before-eval idea is correct, but “parse failure” alone is insufficient.

Required test matrix:

- malformed syntax;
- valid single form;
- multiple top-level forms if allowed;
- valid form with runtime error;
- malformed definition;
- mutation followed by later failure;
- deliberate large input;
- retry exhaustion.

The key invariant is: **validation failure causes zero state mutation.**

### Phase 3 — Provider widening
**Keep, but remove provider ownership.**

The upstream extension registers a fixed Fireworks model list. This is the wrong abstraction for the fork. The extension should consume the selected Pi provider/model and determine constraint capability.

Recommended modes:

1. `grammar` — provider accepts grammar-constrained output.
2. `structured` — provider supports a suitable schema mechanism.
3. `retry` — ordinary text + host validation.
4. `plain` — only if validation/loop policy remains safe.

Do not silently fall from grammar to unrestricted execution. Every mode still passes through host validation.

### Phase 4 — MCP bootstrap
**Keep, but add supervisor/lifecycle.**

Upstream already has MCP + worker jobs. Reuse it. The fork should not write a second MCP implementation.

Required additions:

- allowlist;
- health state;
- startup failure isolation;
- shutdown;
- timeout policy;
- capability manifest;
- no duplicate outer tools.

### Phase 5 — User channel
**Keep.**

Make `reply`/`halt` part of a small explicit protocol. A model-generated string should not be confused with a diagnostic or raw Lisp result.

Recommended result envelope:

```text
kind: reply | data | diagnostic | halted | error
value
renderHint
```

### Phase 6 — Persistence
**Keep, but narrow authority.**

The plan currently says `restore!` may load bindings into the REPL. That is too permissive for durable state. Prefer structured state restoration into approved namespaces; do not execute arbitrary persisted source by default.

### Phase 7 — Vestige reify loop
**This is the real v1 architecture milestone. Promote to a dedicated subsystem.**

The existing sequence is correct:

`recall -> reify -> act -> gated ingest`.

But formalize:

- request ID;
- memory scope;
- retrieval budget;
- contribution envelope;
- stale-data semantics;
- ingest eligibility;
- maximum writes;
- failure/degradation behavior.

The model should never be the component that decides whether recall happens.

### Phase 8 — Optional harden
**Rename and split.**

Recommended:

- Phase 8A: prompt/context optimization — optional.
- Phase 8B: evaluation isolation — mandatory before hostile/untrusted workloads.
- Phase 8C: provider adapter extraction — optional engineering cleanup.
- Phase 8D: worker isolation — required if untrusted MCP/RLM capabilities expand.

The word “optional” currently understates security/reliability work.

### Phase 9 — Context contributors
**Move the data model into Phase 7; keep the registry feature here.**

This follows Autolith's strongest transferable pattern. Phase 7 should emit one `related-memories` contribution using the final envelope. Phase 9 adds extensibility.

### Phase 10 — Bounded RLM
**Keep optional and make containment the acceptance criterion.**

Do not start until real long-context coding tasks demonstrate a need.

Before code, define a budget algebra:

```text
RunBudget
  calls_remaining
  output_tokens_reserved
  input_tokens_observed
  depth_remaining
```

Child frames inherit a budget subtree, never the parent's conversation/capabilities.

### Phase 11 — Agendas/papercuts
**Good feature; simplify initial model.**

Use Vestige as persistence. Do not recreate Autolith's versioned state database. Store canonical records with IDs/status/evidence and derive views from them.

### Phase 12 — Soft generations
**Reframe as logical snapshots.**

Do not call this “recovery” without qualification. It restores logical mind state, not arbitrary interpreter state.

## Revised phase structure

```text
0  Baseline + profiles + runtime contract
1  Prompt assembly + capability manifest
2  Validation + safe evaluation
3  Provider constraint adapter
4  MCP supervisor + in-image tools
5  User/result protocol
6  Mind persistence + state namespaces
7  Mandatory recall/reify/ingest pipeline
8  V1 hardening + isolation + observability

9  Contributor registry
10 Bounded inference/RLM
11 Structured agenda/papercuts
12 Logical snapshots
```

## Add a Phase 0.5: contracts and invariants

Before substantial implementation, define and test these invariants:

1. `pi-default` never enters the Lisp path.
2. `lisp-mind` never evaluates unvalidated model text.
3. Host-generated forms are distinguishable from model-generated forms.
4. Turn retrieval is replaced, not accumulated.
5. Durable writes require host approval/evidence.
6. Provider transformations preserve unrelated request fields.
7. MCP failure does not destroy the REPL.
8. A REPL error does not automatically destroy valid prior definitions.
9. Child inference cannot access parent conversation or unrestricted capabilities.
10. No secret appears in prompt, telemetry, snapshot or ordinary output.

## Acceptance-driven execution

Each phase should ship with a fixture and an observable log rather than only a manual checklist.

Example:

```text
fixture: malformed-lisp
expect: validation_failed
expect: repl_state_hash unchanged
expect: retry_count <= 3
```

```text
fixture: two-topic-memory
expect: recall(user1) != recall(user2)
expect: retrieved_set_size <= K
expect: second_turn_context contains no first-turn retrieval unless recalled
```

```text
fixture: cache-plus-grammar
expect: cache fields preserved
expect: grammar only when capability=true
```

This will turn the project from a plan into a reproducible engineering system.

## Definition of Done for v1

A v1 release should require:

- 0–7 implemented;
- 8B evaluation isolation at minimum for the supported trust model;
- provider/cache regression tests;
- MCP startup/shutdown tests;
- memory recall/reify/ingest integration tests;
- prompt assembly snapshot tests;
- secret-leak tests;
- failure-injection tests for Vestige, MCP, provider and REPL;
- daily-use coding benchmark comparing `pi-default` and `lisp-mind`.

Do not gate v1 on Autolith-inspired RLM or recovery features.
