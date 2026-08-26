# Recommended Architecture — Pi-Lisptc v2

## Executive architectural change

The current design is conceptually correct but under-specifies the seams. The fork should explicitly implement **three planes plus one policy boundary**.

```text
                         MODEL
                           |
                           | generated Lisp / requested work
                           v
┌────────────────────────────────────────────────────────────────┐
│ PI HOST / CONTROL PLANE                                       │
│                                                                │
│ session lifecycle | provider selection | prompt assembly       │
│ constraint adapter | context contributors | budgets           │
│ Vestige recall/ingest | capability policy | observability     │
└──────────────────────────────┬─────────────────────────────────┘
                               |
                         versioned bridge
                               |
┌──────────────────────────────▼─────────────────────────────────┐
│ LISPTC EXECUTION PLANE                                        │
│                                                                │
│ persistent AgentRepl | lexical state | macros | mind state    │
│ MCP bindings | jobs runtime | trusted host forms             │
└──────────────────────────────┬─────────────────────────────────┘
                               |
                       durable/service APIs
                               |
┌──────────────────────────────▼─────────────────────────────────┐
│ KNOWLEDGE / DURABILITY PLANE                                  │
│                                                                │
│ Vestige memories | preferences | agendas | papercuts          │
│ snapshots | bounded inference traces / content objects        │
└────────────────────────────────────────────────────────────────┘

POLICY BOUNDARY: model-authored Lisp is untrusted input even though
it executes inside the user's process. Host policy decides which
operations are available and which durable mutations are accepted.
```

## 1. Authority model

Every important state needs one owner.

| State/capability | Authority | Lifetime |
|---|---|---|
| Pi session transcript | Pi | session/history |
| Provider/model selection | Pi | request/session |
| Prompt/context assembly | Pi-Lisptc host | request |
| Model output validity | host parser/validator | request |
| Lisp definitions and live variables | lisptc | session |
| MCP connections | host + lisptc MCP subsystem | session |
| Turn-local retrieved evidence | host | one turn |
| Durable memories | Vestige | durable |
| Preferences | explicit persistence layer | durable |
| Agenda/papercuts | structured durable layer | durable |
| RLM budget | host | one inference run |
| Secrets | secret subsystem | scoped; never ordinary prompt state |

No feature should silently create a second authority for a row in this table.

## 2. Runtime contract

Introduce an internal TypeScript contract before feature implementation becomes broad.

```text
HostSession
  start(options)
  evaluateTrusted(form)
  evaluateModel(code)
  validate(code)
  reset(mode)
  snapshot()
  shutdown()

EvaluationResult
  status: ok | parse-error | eval-error | host-error
  value
  output
  diagnostics[]
  stateChanges[]
  durationMs
```

This is deliberately narrower than the complete interpreter API. The fork should depend on the contract, not on random internal fields of `AgentRepl`.

### Trusted vs model evaluation

At least two paths are required:

- `evaluateTrusted`: host-generated forms such as reification and bootstrap.
- `evaluateModel`: model-authored Lisp after validation and policy checks.

Do not represent both as the same unrestricted helper. This becomes essential once `mind/*`, snapshots and RLM exist.

## 3. Session lifecycle

Use a deterministic lifecycle:

```text
session_start
   |
   +--> resolve profile
   +--> create/reuse Repl
   +--> load prelude
   +--> initialize MCP
   +--> initialize memory/context services
   +--> publish ready state
   |
   v
user message
   |
   +--> host recall
   +--> build context contributions
   +--> provider request
   +--> validate model output
   +--> evaluate
   +--> collect result/telemetry
   +--> optional gated durable ingest
   |
   v
session_end
   |
   +--> stop new work
   +--> flush/close MCP workers
   +--> optional snapshot
   +--> persist only explicitly durable state
```

The current plan has pieces of this sequence distributed across phases. Consolidate it into one lifecycle document and one implementation module.

## 4. Prompt architecture

Do not make the giant interpreter source the only semantic contract forever.

### Bootstrap v1

Keep the upstream `INTERPRETER_SOURCE` strategy because it is authoritative and expedient.

### Stable v1.1

Split the prompt into:

1. Pi coding core.
2. Lisptc language contract.
3. Available capability manifest.
4. Current context contributions.
5. Optional source/reference material.

The language contract should contain the stable semantic essentials and pointers/identifiers for the complete source. Cache the invariant sections aggressively.

### Important correction

The model should not need the full MCP implementation source merely to know which tools exist. Give it a generated capability manifest from the live registry. The full interpreter source remains available as authoritative reference material but should not be repeated unnecessarily.

## 5. Constraint adapter

Create one host module:

```text
ConstraintAdapter
  resolve(provider, model)
       -> grammar | json-schema | retry | plain
  transform(request, capability)
  validate(response, capability)
  retryPolicy(error)
```

It must be compositional:

```text
original request
    -> cache-preserving transformations
    -> provider constraint transformation
    -> final request
```

Never reconstruct the whole provider payload from a partial object.

## 6. Validation architecture

The correct sequence is:

```text
assistant text
   |
   +--> extract text parts
   +--> fence normalization
   +--> lexical/read validation
   +--> exactly-one-form / accepted-program validation
   |
   +-- failure --> structured retry; NO mutation
   |
   +--> optional policy validation
   +--> eval in live image
   +--> structured result
```

Separate these errors:

- `ParseError`: source cannot be read.
- `ProgramPolicyError`: source is syntactically valid but violates host policy.
- `EvalError`: valid program failed at runtime.
- `HostError`: bridge/service failed.

A runtime exception must not automatically mean the entire image is corrupt.

## 7. MCP architecture

Reuse upstream lisptc's MCP implementation. It already has:

- local command and remote URL connections;
- OAuth support;
- Lisp/JSON conversion;
- tool schema validation;
- server lifecycle;
- worker-backed asynchronous jobs.

Pi-Lisptc should add a **MCP supervisor** responsible for:

- configured server allowlist;
- startup ordering;
- per-server timeout;
- shutdown;
- restart policy;
- failure visibility;
- capability manifest generation.

Do not duplicate MCP transport code in the Pi extension.

## 8. Memory architecture

Use a one-way authority flow:

```text
Vestige
  | recall
  v
Host context envelope
  | bounded evidence
  v
lisptc working mind
  |
  | evidence-backed note
  v
Host ingest policy
  |
  v
Vestige
```

The model can request a note, but the host decides whether it qualifies for durable ingest. This matches the project's `host enforces` principle.

### Retrieval envelope

Every hit should carry:

```text
id
score
scope
source
updatedAt
excerpt
provenance
stalenessHint
```

The model should see excerpts as **data, not instructions**. This is directly aligned with Autolith's context-contributor implementation.

## 9. Context contributions

Move the Phase 9 data model conceptually into Phase 7.

```text
Contribution {
  id
  class: mandatory | advice
  priority
  lifetime: turn | session | durable-reference
  instruction
  evidence
  source
  digest?
  maxChars
}
```

Phase 7 may implement only `related-memories`; Phase 9 then generalizes the registry. This avoids changing the context injection architecture later.

## 10. RLM architecture

If Phase 10 proceeds, use Autolith's containment model as the specification:

- child has private conversation;
- explicit context views;
- explicit contract;
- shared hard budget;
- bounded depth;
- no unrestricted inherited capabilities;
- parent receives value + trace reference, not child transcript.

Do **not** implement RLM as a Lisp function that simply calls the normal Pi turn loop recursively. That would pollute the main conversation and defeat the purpose.

## 11. Snapshots

Phase 12 should snapshot logical mind state, not pretend to snapshot an interpreter image.

Good:

- preferences;
- pins;
- project invariants;
- skill metadata;
- agenda references.

Bad:

- arbitrary closures;
- worker handles;
- MCP sockets;
- provider tokens;
- whole transcript;
- transient retrieval.

Restore should be a controlled state import followed by validation, not arbitrary source execution from a snapshot file.

## 12. Observability

Add structured events from the beginning:

```text
session_started
repl_initialized
mcp_ready / mcp_failed
memory_recall
context_packed
provider_request
constraint_mode
validation_failed
retry
repl_eval
repl_reset
memory_ingest
snapshot_created
```

Each event should have a request/turn correlation ID. This will make the system debuggable without dumping model context or secrets.

## 13. Security posture

The project currently frames the interpreter as an action channel. That is useful but means model-authored Lisp is effectively code execution with user privileges.

Therefore:

- MCP servers must be allowlisted/configured;
- file-system scope must be explicit;
- secrets must remain tainted and non-printing;
- durable writes require evidence;
- RLM workers need capability restrictions;
- snapshots must exclude secrets;
- host policy must never depend solely on prompt compliance.

## 14. Recommended module layout

```text
src/extension/
  host/
    session.ts
    runtime-contract.ts
    lifecycle.ts
    policy.ts
    telemetry.ts
  prompts/
    pi-coding-core.ts
    lisptc-channel.ts
    capability-manifest.ts
    source-reference.ts
  constraints/
    adapter.ts
    capabilities.ts
    retry.ts
  repl/
    adapter.ts
    validation.ts
    results.ts
  mcp/
    supervisor.ts
    bootstrap.ts
  memory/
    recall.ts
    contributions.ts
    ingest.ts
  persistence/
    prefs.ts
    snapshots.ts
  rlm/
    budget.ts
    context.ts
    infer.ts
```

This is intentionally a host-oriented organization. The upstream interpreter remains in its own package/repository boundary.

## 15. Architectural non-goals

Do not introduce:

- a second Lisp interpreter;
- a second MCP transport stack;
- a second durable memory database;
- a second Pi session engine;
- a forked provider registry unless Pi's API makes it unavoidable;
- Autolith's SBCL image model;
- private self-modification Git infrastructure.

The fork's value is orchestration and policy, not reimplementing every subsystem it integrates.
