# Roadmap Critique and Revised Execution Plan

## Assessment

The proposed direction is strong, but feature sequencing should change. The fork already inherits a non-trivial interpreter, MCP integration, jobs, and Pi extension machinery. Therefore the first milestone should stabilize boundaries rather than add language features.

## Revised phases

### Phase 0 — Baseline and invariants

- pin upstream baseline;
- establish reproducible tests;
- document current runtime behavior;
- create divergence ledger;
- define compatibility policy.

**Exit gate:** upstream behavior is captured by tests and fork changes are attributable.

### Phase 1 — Runtime contract

Implement the host/runtime interface, request IDs, capability discovery, cancellation and budgets.

**Exit gate:** every externally meaningful operation crosses one explicit boundary.

### Phase 2 — Safety and transactional state

Implement validation-before-eval, resource limits, checkpoints, rollback semantics and failure injection.

**Exit gate:** malformed or hostile generated code cannot bypass policy; failed evaluations have deterministic state outcomes.

### Phase 3 — Pi integration

Integrate model/provider/context access through Pi rather than maintaining a parallel provider registry. Remove provider-specific assumptions from the fork where feasible.

**Exit gate:** model selection and capabilities have one source of truth.

### Phase 4 — MCP/jobs hardening

Reuse upstream mechanisms. Add cancellation, lifecycle events, quotas, observability and integration tests rather than a parallel implementation.

**Exit gate:** long-running and external operations are bounded and observable.

### Phase 5 — Persistence/checkpointing

Separate working state, snapshots and durable memory. Define serialization/versioning and restore compatibility.

**Exit gate:** restart/restore tests pass across supported versions.

### Phase 6 — Context contributors

Introduce typed, bounded context contributions. Add Vestige as one contributor rather than making memory synonymous with prompt construction.

**Exit gate:** context assembly is deterministic under a fixed budget.

### Phase 7 — Cognitive utilities

Add Lisp-facing abstractions for plans, summaries, reflection and reusable working-memory operations. Keep them library-level rather than embedding policy in the interpreter.

### Phase 8 — RLM

Add bounded recursive computation with child budgets and capability reduction.

**Exit gate:** adversarial recursion/resource tests pass.

### Phase 9 — Optional Autolith-inspired advanced features

Evaluate self-modification, richer recovery, and image-like persistence only after the core runtime is proven. Most should remain optional integrations rather than core dependencies.

## Features to reject or defer

- unrestricted self-modifying runtime;
- autonomous provider switching inside Lisp;
- duplicate memory authority;
- unrestricted recursive agents;
- interpreter reset as transactional rollback;
- large architectural rewrites merely to resemble Autolith.

## Execution principle

Every phase should produce a runnable artifact and an explicit exit gate. Do not allow feature accumulation to substitute for runtime correctness.
