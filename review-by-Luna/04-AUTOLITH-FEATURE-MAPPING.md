# Autolith Feature Mapping

## Reuse directly as design patterns

### Bounded context contribution

Autolith demonstrates a useful abstraction: memory/context providers contribute bounded material to a larger prompt. Pi-Lisptc should generalize this into a typed contributor interface with provenance, priority and cost.

### Recursive language-model computation

Autolith's RLM direction is valuable because it treats recursive computation as a resource-governed operation. Pi-Lisptc should reproduce the governance model, not the underlying runtime architecture.

### Explicit resource accounting

Depth, token/output limits and execution budgets should be first-class runtime concepts.

## Adapt, do not copy

### Self-modification

Autolith's live-image/self-mutation concepts are powerful but conflict with a host-controlled Pi architecture if imported wholesale. Prefer versioned code artifacts, explicit reload boundaries and transactional state.

### Recovery images

The concept of recoverable runtime state is useful. The implementation should instead use versioned Pi-Lisptc snapshots with compatibility metadata.

### Image-centric persistence

A Lisp image is not automatically the right persistence format for a Pi extension. Persist logical state and durable knowledge separately from executable runtime internals.

## Do not make core dependencies

- SBCL-specific mechanisms;
- Autolith's complete orchestration model;
- autonomous mutation of the host;
- duplicated memory stores;
- unrestricted child agents.

## Recommended feature translation

| Autolith concept | Pi-Lisptc translation |
|---|---|
| Memory contributor | Typed host context contributor |
| RLM | Bounded child evaluation service |
| Image/recovery | Versioned logical snapshot |
| Self mutation | Explicit code artifact + reload transaction |
| Persistent knowledge | Vestige-backed durable memory |
| Resource budget | Pi runtime execution budget |

The strongest integration is therefore conceptual: use Autolith to inform interfaces and safety invariants while keeping lisptc/Pi as the actual runtime foundation.
