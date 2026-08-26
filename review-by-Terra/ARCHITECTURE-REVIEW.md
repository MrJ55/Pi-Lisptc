# Pi-Lisptc independent architecture review

## Scope and method

Independent review of `MrJ55/Pi-Lisptc`, conducted without reading or relying on `review-by-Luna`. This assessment is grounded in Pi-Lisptc's plan/ADR/source layout, Lisptc's workspace, interpreter modules, and test layout, and Autolith's source subsystem layout.

Observed facts:

- Pi-Lisptc contains phase plans 00--12, ADRs 0001--0009, a seeded `src/prelude/mind-api.lisp`, and an intentionally empty `src/extension`.
- Lisptc is a pnpm/Turbo TypeScript monorepo with `env`, `interpreter`, `repl`, and shared TypeScript configuration packages. Its interpreter source includes `lisp.ts`, grammar/source/arithmetic modules, MCP/MCP-broker/MCP-OAuth modules, jobs, and secrets. Its tests cover reader, grammar, errors, lists, numbers, strings, macros, recursion, imports, source/prelude, secrets, MCP, OAuth, printing, and fixtures.
- Autolith is a Common Lisp system with distinct agent, application, configuration, conversation, core, inference, MCP, provider, resource, self, state, task, tool, worker, and related subsystems.

## Executive assessment

The product direction is sound: retain Lisptc as the Lisp substrate and add profile-aware context, controlled capabilities, and later durable cognitive artifacts. The main risk is accidentally building three coupled systems at once: a forked interpreter, an agent host, and an Autolith-inspired persistent runtime.

**Recommendation:** keep the interpreter upstream-compatible; implement Pi features in a separate extension host with typed boundaries; treat Autolith as a source of narrowly adopted patterns, not a topology to transplant.

## Target architecture

### Layer 0 — interpreter

Owns parsing, evaluation, Lisp values, macro/control-flow semantics, imports, and existing prelude/source behavior. It must not depend on provider, MCP authorization, durable memory, or user-channel adapters.

Fork policy:

- Pin an exact Lisptc revision in `UPSTREAM.md`.
- Record every divergence in `FORK-DELTA.md`, including rationale, test, and upstreaming decision.
- Prefer host hooks/adapters to edits in evaluator internals.
- Run the upstream interpreter test suite unchanged in CI.

### Layer 1 — Pi extension host

Owns profile selection, context assembly, lifecycle, budgets, durable events, capability policy, and audit.

```text
src/host/
  profile-registry.ts
  context/{schema,assembler}.ts
  capabilities/{policy,mcp}.ts
  providers/adapter.ts
  memory/{event-store,materializer}.ts
  runtime/{turn-controller,budgets}.ts
  audit/ledger.ts
src/prelude/mind-api.lisp
```

Dependency direction is fixed: prelude -> host capability API -> adapters. Adapters do not import evaluator internals.

### Layer 2 — adapters

Provider, MCP, persistence, image, and UI integrations are replaceable adapters. They receive policy-filtered requests and minimal credentials; they never receive ambient evaluator authority.

### Layer 3 — structured surfaces

User-channel, diagnostics, trace, and soft-generation surfaces consume stable events/schemas; they never derive authoritative state by parsing prompts or model prose.

## Essential contracts

### Context candidate

```ts
type ContextCandidate = {
  id: string; contributor: string; version: string;
  scope: 'turn'|'session'|'workspace'|'user'; priority: number;
  content: string; estimatedTokens: number;
  provenance: Array<{kind:string; id:string; digest?:string}>;
  sensitivity: 'public'|'private'|'secret'; expiresAt?: string;
};
```

Contributors emit candidates only. The assembler validates, filters by profile/sensitivity/expiry, applies deterministic ordering, enforces budget, renders, and stores a manifest plus digest. No contributor mutates the final prompt directly.

### Capability request

```ts
type CapabilityRequest = {
  capability: string; operation: string; arguments: unknown;
  profile: string; turnId: string;
};
```

The host validates schema, evaluates a profile-scoped grant, applies budgets, emits an audit decision, invokes an adapter, and returns a typed result. Lisp gets a stable structured result/error rather than an adapter implementation detail.

### Durable memory and reification

Canonical data is append-only schema-versioned events. Vestiges/summaries are materialized views with input event digests, generator/schema version, replacement key, status, and timestamp. Replace active materializations atomically; preserve superseded records for audited rollback/retention. Never accumulate old and new versions blindly in context.

## Plan critique

Retain and strengthen these directions:

- Merge prompts rather than replace them, using the structured candidate/manifest contract.
- Validate before eval, and extend that rule to persistence writes, tool dispatch, provider output reuse, and materialization activation.
- Reify by replacement rather than accumulation, with atomicity, provenance, expiry, and rollback.
- Keep provider modes/profile separation, backed by a provider capability matrix.
- Keep bounded RLM work late, but enforce runtime budgets rather than relying on advisory limits.

Add ADRs for: extension-host boundary; upstream synchronization; canonical events versus materialized memory; capability grants/MCP policy; and redacted replayable observability.

## Primary risks

| Risk | Mitigation |
|---|---|
| Fork drift around central evaluator code | Minimal delta, pinned upstream, unchanged upstream suite, differential tests |
| Non-deterministic prompt/context | Structured candidates, stable order, manifests, rendering digests |
| Memory poisoning/staleness | Append-only events, provenance, expiry, rebuildable materializations |
| MCP privilege escalation | Profile grants, allowlists, schemas, approval/budget gates, audit |
| Provider leakage into semantics | Provider-neutral adapters and capability matrix |
| Premature Autolith port | Adopt one behavior at a time behind Pi-owned interfaces |
| RLM cost/loops | Enforce depth/time/model/tool/token/cost/artifact budgets |

## Architecture invariant

> The interpreter evaluates Lisp; the Pi host decides which capabilities exist for a turn; adapters perform approved effects; the event ledger explains the effective context and every side effect.

Do not start durable persistence/reification until baseline compatibility, deterministic context manifests, stable host boundaries, and end-to-end capability audits exist.