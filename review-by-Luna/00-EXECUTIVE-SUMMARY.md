# Pi-Lisptc — Luna Architecture Review

**Review basis:** source-level audit of `MrJ55/Pi-Lisptc`, `1hachem/lisptc`, and `lambda-symbolics/autolith` at the commits reviewed on 2026-08-26. This review deliberately goes beyond README claims and traces the implementation boundaries that the plan depends on.

## Verdict

**The project direction is strong and worth pursuing, but the current plan is implementation-ready only after one architectural correction: Pi-Lisptc should be treated as a host-controlled orchestration layer around an embedded lisptc runtime, not as a prompt customization project.**

The existing plan correctly identifies the two largest upstream problems: upstream lisptc's Pi extension replaces Pi's system prompt and clears active tools, while its provider hook unconditionally installs Fireworks grammar. The plan also correctly separates durable Vestige memory from live REPL state and makes host-side recall/reification mandatory.

However, several phase boundaries are presently too optimistic. In particular:

1. **Phase 1 must establish a formal host/repl boundary and session lifecycle before prompt work is considered complete.**
2. **Phase 2 must distinguish syntax validation from semantic evaluation and must not rely on the current upstream reset-on-any-throw behavior.**
3. **Phase 4 must treat MCP as a lifecycle-managed subsystem, not merely a bootstrap script.** The upstream interpreter is synchronous while its MCP/jobs layer uses worker threads and blocking `Atomics.wait`; this is workable, but it creates explicit lifecycle, timeout, shutdown, and concurrency obligations.
4. **Phase 7 is the real architectural milestone.** Auto-recall and reification should be specified as a host pipeline with an explicit context contract, not as incidental Lisp calls.
5. **Phase 8 should not be called optional hardening in the architecture.** At least prompt budgeting, eval isolation, secret exclusion, and provider/cache composition are release gates for a trustworthy v1.
6. **Autolith should be mined for interfaces and invariants, not copied structurally.** Its strongest ideas for this project are bounded context contributions, explicit state classes, isolated inference frames, immutable/content-addressed context, and exact budget accounting. Its live SBCL image/recovery/self-mutation architecture should remain outside the core Pi deployment.

## Most important recommendation

Adopt a three-plane architecture:

```text
                 ┌───────────────────────────────┐
                 │ Pi host / control plane       │
                 │ provider + session + policy   │
                 │ recall + budgets + lifecycle  │
                 └──────────────┬────────────────┘
                                │ explicit bridge
                 ┌──────────────▼────────────────┐
                 │ lisptc execution plane         │
                 │ persistent REPL + Lisp image  │
                 │ MCP bindings + mind state     │
                 └──────────────┬────────────────┘
                                │ durable protocol
                 ┌──────────────▼────────────────┐
                 │ durable knowledge plane        │
                 │ Vestige + files + snapshots  │
                 └───────────────────────────────┘
```

The model is an actor inside this system, not the owner of it. The host decides what context enters, which capabilities exist, what may mutate state, and how much work may be performed.

## What is already right

- Two profiles (`pi-default` and `lisp-mind`) are the correct compatibility strategy.
- Merge Pi's coding prompt rather than replacing it.
- Keep outer tool schemas minimal in lisp-mind and expose tools as Lisp bindings.
- Validate before session evaluation.
- Use grammar when the provider supports it and validate/retry otherwise.
- Preserve cache-related provider fields rather than replacing payloads.
- Treat Vestige as durable memory and the REPL as working state.
- Replace turn-local retrieval instead of accumulating it.
- Cap pins, skills, context contributions, ingests, and RLM work.
- Make Autolith adaptations additive and evidence-driven.

## What must change

### A. Add an explicit Runtime Contract before Phase 1

Define one versioned contract for:

- `Host -> Repl`: initialize, evaluate trusted form, evaluate model form, reset, snapshot, shutdown.
- `Repl -> Host`: value, printed output, structured error, state-change metadata.
- `Host -> Provider`: assembled prompt/context, capability mode, cache metadata.
- `Host -> Vestige`: recall/ingest requests with scope and evidence policy.

This contract becomes the seam that prevents later features from leaking into one another.

### B. Make validation a real parser API

The current upstream extension feeds model text directly to `repl.eval()` and resets the entire interpreter if evaluation throws. The fork should introduce a reusable `parse/validate` path that proves the text is a complete accepted form before execution. Semantic/runtime errors should be separate from parse rejection.

### C. Replace hard-coded provider knowledge with capability negotiation

The upstream Pi extension registers a fixed Fireworks model list and unconditionally adds grammar to every provider request. Pi-Lisptc should resolve capabilities from the actual selected provider/model and compose request transformations rather than owning the provider registry.

### D. Treat context as typed data

Do not make `mind_active` a generic string forever. Introduce a typed contribution envelope with class, priority, lifetime, provenance, size, and optional digest. This can begin internally in Phase 7 and become the Phase 9 contributor registry without another architectural rewrite.

### E. Separate state classes

At minimum:

- conversation transcript — Pi/session authority
- working mind — lisptc authority
- turn evidence — host authority, ephemeral
- durable memories — Vestige authority
- user preferences — durable configuration authority
- agenda/papercuts — structured durable state
- inference traces — bounded diagnostic state

This is one of Autolith's most transferable architectural lessons.

## Revised release definition

Call **v1** the point at which Phases 0–7 plus the mandatory portions of 8 are stable in daily coding use. Do not wait for RLM, agendas, papercuts, or generations to call the core architecture successful.

A credible v1 acceptance suite should demonstrate:

- normal Pi mode is unchanged;
- lisp-mind retains Pi coding context;
- malformed model output never mutates the REPL;
- provider-specific constraints work without corrupting cache metadata;
- MCP tools work through the Lisp layer and shut down cleanly;
- every user turn gets bounded, host-forced recall;
- retrieved state is replaced, not accumulated;
- durable ingest is gated and evidence-backed;
- secrets cannot enter prompts, snapshots, or ordinary REPL output;
- a broken Vestige/MCP/provider dependency degrades to useful coding rather than taking down Pi.

## Bottom line

**Proceed, but rebase the plan around explicit contracts, lifecycle ownership, and typed context.** The current design has the right strategic insight; the main risk is allowing a series of individually sensible features to become a tightly coupled extension with hidden state and unclear authority boundaries.
