# Autolith Feature Mapping — What Pi-Lisptc Should and Should Not Adopt

## Principle

Autolith is architecturally richer because it owns a Common Lisp image, terminal, provider stack, durable state, workers and recovery model. Pi-Lisptc does not need to become Autolith. The useful exercise is to extract invariants that solve the same problems inside Pi's existing host model.

## 1. Context contributors — ADOPT

Autolith's `memory-related-context` is the strongest near-term donor. It has explicit limits: six results, 1900 evidence characters and 180-character excerpts. It assigns priority and turn lifetime and explicitly labels excerpts as potentially stale data.

Pi-Lisptc should adopt:

- typed contributions;
- priority;
- lifetime;
- mandatory/advice classes;
- hard size limits;
- provenance;
- stale-data warning.

Do not copy the Common Lisp generic-function protocol. A TypeScript registry is sufficient.

## 2. State separation — ADOPT

Autolith separates conversations, memories, agendas, papercuts and input-vault state. Pi-Lisptc should mirror the conceptual separation:

```text
Pi transcript        -> authoritative conversation
lisptc mind          -> working state
Vestige              -> durable memory
agenda               -> structured durable plan
papercut             -> structured durable defect
RLM trace            -> diagnostic/inference history
snapshot             -> logical recovery state
```

This prevents “memory” from becoming a single bucket containing unrelated state.

## 3. RLM containment — ADOPT SELECTIVELY

Autolith's RLM design gives child frames:

- explicit task;
- explicit context views;
- explicit contract;
- private ephemeral conversation;
- shared bounded budget;
- bounded recursion depth;
- restricted capabilities;
- returned value + trace rather than transcript.

Pi-Lisptc should implement these invariants if RLM is built. In particular, do not recursively invoke the normal Pi agent session.

## 4. Content-addressed context — ADOPT WHEN NEEDED

Autolith stores large context outside the model prompt and exposes label/size/digest descriptors. Pi-Lisptc should use this once Phase 10 needs large corpora.

Start simple:

```text
ContextDescriptor
  id
  label
  size
  sha256
  source
```

The parent model sees the descriptor. The child frame receives an explicitly authorized view.

Do not implement a complete resource URI hierarchy until an actual use case requires it.

## 5. Budget algebra — ADOPT

Autolith's RLM budgets are not merely counters. Calls, output reservations and recursion depth are shared across descendants, and exhaustion is explicit.

Pi-Lisptc should adopt hard bounds for:

- provider calls;
- recursion depth;
- output tokens;
- wall-clock time;
- parallel fan-out;
- context bytes.

The first implementation can use a TypeScript budget object; it does not need Autolith's condition system.

## 6. Traces — ADOPT LIGHTWEIGHT VERSION

Every RLM operation should produce a trace ID and parent trace ID. Store:

- task;
- model/provider;
- context descriptors;
- budget allocation;
- child calls;
- result/error;
- usage.

Keep the primary Pi conversation clean. This is one of the most important Autolith lessons.

## 7. Agendas — ADOPT THE CONCEPT, NOT THE STORE

Pi-Lisptc should maintain an agenda as structured durable records backed by Vestige or another already-selected durable authority.

Do not introduce Autolith's `sexp-store` merely to reproduce its data model.

## 8. Papercuts — ADOPT

The papercut pattern is useful because it turns “something went wrong” into a durable, evidence-backed object instead of an ephemeral chat remark.

Minimum schema:

```text
id
status: open | closed
summary
body
evidence
createdAt
updatedAt
resolution?
```

## 9. Generations — ADOPT AS LOGICAL SNAPSHOTS

Autolith's actual generation mechanism is a Lisp image/recovery architecture. That should not be ported.

Pi-Lisptc should instead snapshot approved logical state. Make the distinction explicit in all docs and UI.

## 10. Self mutation — DO NOT ADOPT

Autolith's `self.*` machinery is an agent operating-system feature: active-image introspection, mutation journals, restart handling, definition signatures and private image commits.

Pi-Lisptc should not implement this as part of the core. Model-authored Lisp is already a powerful mutation surface; adding self-modifying host infrastructure before the basic system is reliable would multiply risk.

## 11. Recovery images — DO NOT ADOPT

Autolith's pristine recovery core makes sense because the active Common Lisp image can mutate itself deeply. Pi-Lisptc runs as an extension in a Pi process and should rely on:

- clean process restart;
- logical snapshot restore;
- sandboxed evaluation where needed;
- durable source-controlled extension code.

A second bootable image is not justified by the current goals.

## 12. Terminal architecture — DO NOT ADOPT

Autolith owns its terminal/editor/rendering model. Pi already owns the TUI. Pi-Lisptc should integrate through Pi UI hooks and avoid competing terminal state.

## 13. Provider architecture — DO NOT ADOPT

Autolith has its own provider protocol. Pi already has one. The fork should implement a constraint adapter at the Pi provider boundary rather than create another provider client stack.

## 14. Worker model — ADOPT THE ISOLATION PRINCIPLE

Autolith's workers are separate images and are deliberately restricted. lisptc already has a worker-thread job runtime for MCP.

Pi-Lisptc should:

- reuse lisptc jobs;
- define which operations are worker-safe;
- enforce timeout/cancellation policy at the host;
- isolate RLM capability surfaces from the main session.

## 15. Final transfer matrix

| Autolith feature | Pi-Lisptc decision | Reason |
|---|---|---|
| memory-related-context | Adopt | directly solves retrieval/context relevance |
| context contributors | Adopt | clean generalization of Phase 7 |
| state separation | Adopt | prevents memory/state conflation |
| content-addressed context | Adopt later | essential for scalable RLM |
| RLM budgets | Adopt | safety/cost invariant |
| private inference frames | Adopt later | prevents parent contamination |
| inference traces | Adopt light | observability and debugging |
| agendas | Adopt concept | useful durable workflow state |
| papercuts | Adopt concept | evidence-backed defect memory |
| logical snapshots | Adopt | practical continuity |
| sexp-store | Reject | second persistence substrate |
| SBCL image model | Reject | wrong runtime boundary |
| recovery image | Reject | unnecessary for core |
| self.* mutation | Reject | excessive authority/risk |
| Autolith terminal | Reject | Pi already owns UI |
| Autolith provider stack | Reject | Pi already owns providers |

## Core lesson

**Borrow Autolith's contracts, boundaries and invariants; do not borrow its operating system.**
