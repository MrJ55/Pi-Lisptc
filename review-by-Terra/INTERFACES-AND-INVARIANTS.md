# Interfaces and invariants

## Non-negotiable invariants

1. Interpreter isolation: evaluation does not depend on provider, MCP, persistence, or UI adapters.
2. Explicit capability: every side effect is a named request passing schema and policy checks.
3. Deterministic context: structured candidates, stable order, and budget policy determine final context.
4. Provenance: injected context, tool results, and derived artifacts identify sources and versions.
5. Derived-not-canonical: vestiges are replaceable materializations; events/facts are canonical.
6. No ambient authority: adapters receive least privilege.
7. Bounded recursion: nested RLM work has enforced counters and cancellation.
8. Replayable observability: a no-side-effect turn can reconstruct from trace manifest and fixtures.

## Boundary map

```text
User -> input validation -> profile -> context assembler -> provider
                              |             |
Lisp evaluator <-> prelude -> host policy -> adapters (MCP/store/etc.)
                              |
                           audit ledger -> materializers/UI
```

Allowed direction: prelude -> stable host API -> adapters; materializers read durable events and write derived artifacts; interpreter imports none of the adapters/store.

## Profile schema

```ts
type Profile = {
  id: string; version: string; enabledContributors: string[];
  capabilityGrants: Array<{capability:string; operations:string[]}>;
  contextBudget: {maxTokens:number; reserveTokens?:number};
  providerPolicy: {preferred:string[]; requiredCapabilities:string[]};
  persistencePolicy: {mode:'off'|'ephemeral'|'durable'; scopes:string[]};
  approvalPolicy: {requiredFor:string[]};
};
```

Reject unknown contributors/capabilities, invalid budgets, and unavailable required provider capabilities.

## Context algorithm

1. Resolve profile/contributor versions.
2. Run eligible contributors in isolation.
3. Validate candidates.
4. Filter sensitivity, scope, expiry, and policy.
5. Sort by published stable key, such as `(priority, contributor, id)`.
6. Admit within budget and record omission reasons.
7. Render with a versioned renderer.
8. Persist immutable manifest/digest before provider dispatch.

## Capability policy

Before dispatch, resolve profile/turn, operation schema/version, target resource, allowlist, sensitivity, approval requirement, remaining budget, and audit decision.

```ts
type CapabilityResult<T> =
  | {ok:true; value:T; usage?:Usage; auditEventId:string}
  | {ok:false; code:'DENIED'|'INVALID'|'BUDGET'|'UNAVAILABLE'|'FAILED'|'CANCELLED'; message:string; auditEventId:string};
```

## Event/materialization

```ts
type DurableEvent = { id:string; type:string; occurredAt:string;
  scope:{kind:'turn'|'session'|'workspace'|'user'; id:string}; payload:unknown;
  sensitivity:'public'|'private'|'secret'; provenance:Array<{kind:string;id:string;digest?:string}>;
  schemaVersion:number; redactedAt?:string };
type Materialization = { id:string; replacementKey:string; inputEventDigests:string[];
  generatorVersion:string; schemaVersion:number; content:unknown;
  status:'active'|'superseded'|'invalid'|'expired'; createdAt:string };
```

Atomically replace active artifacts by replacement key and retain superseded records according to retention. Do not concatenate generations into future context.

## RLM budget

```ts
type Budget = { maxDepth:number; maxElapsedMs:number; maxModelCalls:number;
  maxToolCalls:number; maxInputTokens:number; maxOutputTokens:number;
  maxCostUsd?:number; maxGeneratedBytes:number };
```

Counters are inherited by children, atomically consumed, and cancellation prevents committing successful materializations.

## Security

Never serialize credentials in context/traces/errors/materializations. Default-deny MCP server/tool access. Require concrete resource identities for destructive actions. Version and validate serialized records. Export redacted traces by default.