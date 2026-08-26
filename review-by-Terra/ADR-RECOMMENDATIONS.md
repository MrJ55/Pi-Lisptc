# ADR recommendations

## ADR-0010: Extension-host boundary

**Status:** proposed

**Decision:** retain upstream-compatible interpreter semantics. A Pi-owned extension host owns profiles, lifecycle, context assembly, capability dispatch, and audit; Lisp sees only a stable versioned prelude/host API.

**Why:** prevents profile/provider/MCP/persistence concerns from migrating into evaluator internals and makes fork synchronization tractable.

## ADR-0011: Pinned upstream compatibility

**Status:** proposed

**Decision:** pin Lisptc revision; maintain `UPSTREAM.md`, `FORK-DELTA.md`, and unchanged upstream test CI. Every divergence carries rationale, test, and upstreaming/maintenance decision.

## ADR-0012: Structured deterministic context

**Status:** proposed

**Decision:** contributors emit validated structured candidates; a sole assembler applies stable order, sensitivity, budget, rendering, immutable manifest, and digest. Direct prompt mutation is prohibited.

## ADR-0013: Canonical events, derived vestiges

**Status:** proposed

**Decision:** append-only schema-versioned events are canonical. Vestiges/reified artifacts are versioned materializations with input digests, replacement keys, expiry/status, and atomic activation.

## ADR-0014: Capability grants for external effects

**Status:** proposed

**Decision:** adapters are callable only through named requests that pass schemas, profile grants, allowlists, approval policy, and runtime budgets, with normalized results and audit records.

## ADR-0015: Provider-neutral capability matrix

**Status:** proposed

**Decision:** model streaming, tools, structured output, vision, grammar, context capacity, cancellation, and usage as adapter-declared capabilities; profiles specify requirements/fallbacks instead of provider-specific core behavior.

## ADR-0016: Runtime-enforced bounded RLM

**Status:** proposed

**Decision:** parent/child operations inherit host-enforced depth, time, model/tool call, token, optional cost, byte, and side-effect budgets. Ledger records consumption and cancellation.

## ADR-0017: Redacted replayable observability

**Status:** proposed

**Decision:** persist redacted turn records for profile version, context manifest/digest, decisions, normalized adapter outcomes, usage, and materialization links. Replay only no-side-effect or fixture-backed work.

## Amendments to current ADRs

- ADR-0001: reference candidates/manifests and prohibit direct mutation.
- ADR-0003: validate persistence, tool dispatch, provider-output reuse, and materialization activation as well as eval.
- ADR-0004: define replacement keys, atomicity, provenance, rollback, and retention.
- ADR-0005: require capability matrix and fallback semantics.
- ADR-0007: add versioning, provenance, sensitivity, budgets, deterministic order, and isolation.
- ADR-0008: enumerate enforced counters and cancellation/transaction rules.
- ADR-0009: generated surfaces are non-authoritative and cannot bypass capability/materialization policy.