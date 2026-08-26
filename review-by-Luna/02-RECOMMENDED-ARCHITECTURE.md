# Recommended Architecture

## Target model

Pi-Lisptc should be a **Pi-hosted Lisp execution and cognition layer**, not a replacement agent framework.

```text
Pi / Host Control Plane
  ├─ provider + model registry
  ├─ permissions / capabilities
  ├─ cancellation / budgets
  ├─ context assembly
  ├─ durable memory policy
  └─ lifecycle / observability
          │ explicit runtime contract
          ▼
lisptc Runtime
  ├─ persistent Lisp environment
  ├─ evaluation
  ├─ macros / closures
  ├─ jobs
  └─ approved MCP/tool operations
          │
          ├── working state
          └── controlled context contributors
                    │
                    ▼
             Vestige / durable knowledge
```

## Authority rule

The host owns anything that can cross the runtime security boundary or affect durable external state. Lisp owns computation inside its sandbox and its own working state.

## Runtime contract

Define a small stable API before adding higher-level features:

- `health()`
- `capabilities()`
- `eval(request)`
- `submit_job(request)`
- `cancel_job(id)`
- `mcp_call(request)`
- `snapshot()`
- `restore(snapshot)`
- `reset()`

`request` should include session/correlation ID, deadline, cancellation token, capability set, and resource budget.

## State model

Separate:

1. **ephemeral evaluation state**;
2. **session working state**;
3. **checkpointed Lisp state**;
4. **durable external memory**.

An evaluation failure must not implicitly decide which category of state is committed.

## Context architecture

Adopt Autolith's contributor idea as a host abstraction:

```text
Contributor -> Contribution {content, source, priority, token_cost, ttl}
             -> policy filter -> budget allocator -> model context
```

The contributor API should be independent of the underlying memory implementation. This allows Vestige, filesystem knowledge, MCP resources, and Lisp-derived summaries to participate without giving any one subsystem control of prompt construction.

## RLM architecture

Later RLM should execute as a bounded child computation:

- maximum recursion depth;
- maximum children;
- wall-clock deadline;
- token/output budget;
- cancellation propagation;
- restricted capabilities;
- explicit result-size limit;
- isolated or transactional child state.

The parent receives a result, not unrestricted access to an arbitrary child runtime.

## Observability

Every eval/job/tool/RLM operation should produce structured events with correlation IDs. Minimum telemetry:

- duration;
- success/failure;
- cancellation;
- resource consumption;
- capability used;
- state mutation/checkpoint identifier.

## Architectural non-goals

Do not make the core dependent on:

- SBCL live images;
- Autolith's self-mutation model;
- unrestricted self-replication;
- provider-specific assumptions;
- a second independent model registry;
- a second durable-memory authority.

## Key decision

The fork should be opinionated about **boundaries and contracts**, while remaining minimally divergent from upstream lisptc's interpreter implementation.
