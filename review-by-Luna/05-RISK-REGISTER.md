# Risk Register and Engineering Controls

| ID | Risk | Likelihood | Impact | Control |
|---|---|---:|---:|---|
| R1 | Pi prompt context is lost during custom prompt replacement | High | Critical | Use Pi prompt-builder contract; snapshot tests |
| R2 | Grammar is sent to unsupported provider | High | Critical | Capability adapter + request regression tests |
| R3 | Cache metadata is overwritten by constraint hook | Medium | High | Immutable/compositional request transforms |
| R4 | Malformed Lisp mutates live REPL | High | Critical | Parse/validate before eval; state-hash test |
| R5 | Runtime exception resets useful session state | High | High | Separate parse/eval errors; reset only on proven corruption |
| R6 | MCP worker remains alive or leaks on session end | Medium | High | Supervisor + shutdown tests |
| R7 | MCP failure prevents coding | Medium | High | Degraded mode; capability state exposed |
| R8 | Retrieved memory becomes prompt injection | Medium | Critical | Mark evidence as data; provenance; never execute recalled text |
| R9 | Memory grows without bound | High | High | per-turn replacement; pin/skill caps |
| R10 | Durable ingest records low-quality model guesses | High | High | evidence requirement + host gate + rate limits |
| R11 | Transcript duplicated into mind state | Medium | High | explicit authority model |
| R12 | RLM recursively invokes normal Pi session | Medium | Critical | private frame API; explicit capability boundary |
| R13 | RLM budget is advisory | Medium | Critical | host-side hard counters/reservations |
| R14 | Snapshot executes arbitrary persisted Lisp | Medium | Critical | structured-state restore; source execution disabled by default |
| R15 | Secrets enter prompt/telemetry/snapshot | Medium | Critical | taint-aware serialization + leak tests |
| R16 | Full interpreter source consumes too much context | High | High | cache measurements; later L0/L1/source-on-demand design |
| R17 | Extension becomes a second Pi implementation | Medium | High | reuse Pi session/provider/TUI APIs |
| R18 | Fork diverges from lisptc semantics | Medium | High | pin upstream commit; tests against interpreter APIs |

## Release-blocking risks

R1, R2, R4, R5, R8, R10, R12, R13 and R15 should block a release intended for unattended or high-trust coding use.

## Failure injection suite

The project should deliberately inject:

- unavailable provider;
- unsupported grammar capability;
- malformed Lisp;
- Lisp runtime exception;
- MCP connection refusal;
- MCP worker timeout;
- Vestige timeout;
- corrupt snapshot;
- oversized context;
- nested RLM budget exhaustion;
- secret-shaped values in results.

The expected behavior should be explicit and machine-checkable.

## Security boundary

The central security fact is simple:

> In lisp-mind, the model writes executable Lisp.

Therefore the system must assume model-authored Lisp can request any capability exposed by the Lisp image. The safe architecture is not “the prompt tells it not to do bad things”; it is “the host exposes only the capabilities the current trust model permits and validates every boundary crossing.”

This is especially important when filesystem MCP, shell-like MCP servers, RLM and durable writes coexist.

## Performance risks

The largest likely performance cost is not the Lisp interpreter. It is repeated prompt/context materialization:

1. full interpreter source;
2. Pi coding context;
3. project context;
4. retrieved memory;
5. context contributions;
6. REPL result history.

Measure each separately. Do not optimize by deleting Pi coding context or useful memory first.

Recommended telemetry fields:

```text
prompt_static_chars
prompt_dynamic_chars
interpreter_source_chars
retrieval_chars
contributor_chars
provider_input_tokens
provider_output_tokens
cache_read_tokens
repl_eval_ms
vestige_ms
mcp_ms
```

## Correctness invariant worth testing globally

For any turn `T`:

```text
state_after(T) = eval(validated_program(T), state_before(T))
```

If validation fails:

```text
state_after(T) = state_before(T)
```

If a dependency fails:

```text
core Pi/lisp-mind session remains usable unless the failed dependency is itself mandatory for the requested operation
```

These invariants are more valuable than a large collection of feature-specific smoke tests.
