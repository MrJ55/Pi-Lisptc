# Source Audit — lisptc × Pi-Lisptc × Autolith

## Purpose

This audit grounds the Pi-Lisptc development plan in the implementation of the three repositories rather than README descriptions alone.

## 1. lisptc: what already exists

The upstream lisptc implementation is considerably more capable than a minimal Lisp REPL. The interpreter already provides persistent evaluation, lexical environments, closures, macros, special forms, asynchronous jobs, MCP integration, schema validation, OAuth-related machinery, and a Pi extension layer.

### Architectural implication

Pi-Lisptc should avoid rebuilding interpreter capabilities that already exist upstream. The fork's primary value should be the host contract, safety/policy layer, persistence semantics, Pi integration, observability, and later cognitive features.

### Important source-level concerns

1. **Evaluation failure recovery is coarse.** The Pi extension can reset the interpreter after an exception. That is useful as a recovery mechanism, but it is not an adequate transactional state model for a long-lived agent runtime.
2. **Provider integration is too opinionated for the fork's intended role.** The provider hook currently performs provider-specific grammar registration. Pi-Lisptc should instead consume Pi's provider/model capabilities through an explicit host interface.
3. **MCP/jobs are already implemented.** Reimplementing asynchronous jobs or MCP plumbing in the fork would create unnecessary divergence.
4. **The model-facing source-generation mechanism is significant.** Lisp semantics are intentionally made available to the model. This should remain deterministic and versioned because changes in interpreter semantics alter the effective programming language exposed to the agent.

## 2. Pi-Lisptc architecture assessment

The fork's core idea is sound: Pi remains the authoritative host while lisptc becomes an executable working layer. The missing architectural contract is an explicit authority boundary.

Recommended ownership:

| Responsibility | Authority |
|---|---|
| Model/provider registry | Pi |
| Tool permissions | Pi |
| Durable memory | Vestige / host policy |
| Lisp evaluation | lisptc |
| Jobs | lisptc, subject to Pi policy |
| MCP capabilities | host-approved MCP layer |
| Context assembly | Pi + controlled contributors |
| Persistent Lisp state | lisptc |
| Snapshot/restore policy | Pi-Lisptc host layer |
| Security/budgets | Pi host |

The fork should expose this contract rather than allowing the Lisp runtime to become a second control plane.

## 3. Autolith: what is worth importing

Autolith's strongest reusable ideas are architectural rather than implementation-specific:

- bounded context contribution;
- explicit contributor interfaces;
- recursive/sub-agent computation with hard budgets;
- separation between working computation and durable knowledge;
- explicit state mutation/recovery boundaries.

The SBCL/live-image assumptions of Autolith should **not** be copied into Pi-Lisptc's core runtime. The useful abstraction is containment and budget enforcement, not the particular Common Lisp image architecture.

## 4. Critical recommendations

### A. Add a Runtime Contract phase before feature expansion

Define stable interfaces for:

- `eval(code)`
- `eval_with_context(code, context)`
- `submit_job`
- `cancel_job`
- `mcp_call`
- `snapshot`
- `restore`
- `reset`
- `health`
- capability discovery

Every host-mediated operation should carry an execution context containing session ID, budget, cancellation state, capability set, and correlation ID.

### B. Make validation-before-eval mandatory

Generated Lisp is executable code. Validation, capability checks, resource limits and policy decisions must occur before evaluation. This should be a release gate, not a later hardening feature.

### C. Use transactional state semantics

Do not rely on whole-interpreter reset as the normal recovery model. Introduce explicit checkpoints and define what mutations are committed when an evaluation fails.

### D. Keep Autolith-inspired context contribution bounded

Context contributors should return typed, bounded contributions with provenance and cost metadata. The host decides what enters the model context.

### E. Treat RLM as a controlled computation service

When RLM is implemented, use explicit recursion depth, wall-clock/token budgets, cancellation, output limits, and child-environment isolation. Do not expose unrestricted recursive self-invocation.

### F. Preserve upstream compatibility deliberately

Track the upstream lisptc baseline and maintain a documented divergence list. Every fork-specific modification should have a reason and, where practical, an upstream compatibility test.

## 5. Bottom line

Pi-Lisptc is viable, but its success depends less on adding Lisp features and more on making the boundary between Pi and the Lisp runtime explicit, deterministic, observable and enforceable. Autolith should supply design patterns for bounded cognition/context and recursive computation—not become a second runtime architecture.
