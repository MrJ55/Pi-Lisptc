# Implementation Checklist — Recommended Order

## Gate 0 — Contracts

- [ ] Define HostSession/RuntimeContract.
- [ ] Define EvaluationResult.
- [ ] Separate trusted host eval from model eval.
- [ ] Define state authority table.
- [ ] Add correlation IDs and structured telemetry.
- [ ] Pin reviewed lisptc commit in `docs/UPSTREAM-PINS.md`.

## Gate 1 — Profiles

- [ ] `pi-default` bypasses the Lisp machinery.
- [ ] `lisp-mind` creates/owns one AgentRepl per intended session.
- [ ] Session start/end are idempotent.
- [ ] No second Pi process is spawned by the extension.

## Gate 2 — Prompt

- [ ] Pi coding role retained.
- [ ] AGENTS/context layers retained.
- [ ] cwd retained.
- [ ] Lisptc channel policy added.
- [ ] Capability manifest generated from live registry.
- [ ] Full interpreter source included initially.
- [ ] Prompt sections measured independently.

## Gate 3 — Validation

- [ ] Fence normalization.
- [ ] Reader-only validation.
- [ ] Exactly-one-program/form policy.
- [ ] Policy validation.
- [ ] Parse failure does not call eval.
- [ ] Runtime failure does not automatically reset state.
- [ ] Retry count is bounded.

## Gate 4 — Provider

- [ ] Capability lookup uses actual selected provider/model.
- [ ] Grammar only where supported.
- [ ] Retry mode available.
- [ ] Cache fields survive transformations.
- [ ] Outbound request snapshots cover each mode.

## Gate 5 — MCP

- [ ] Reuse lisptc MCP package.
- [ ] Server allowlist.
- [ ] Startup supervisor.
- [ ] Worker timeout.
- [ ] Shutdown.
- [ ] Capability manifest.
- [ ] Dependency failure is visible but nonfatal where possible.

## Gate 6 — Mind

- [ ] Prelude loaded before model activity.
- [ ] Typed state namespaces.
- [ ] Pin/skill caps.
- [ ] Preferences persistence.
- [ ] Turn retrieval is replace semantics.

## Gate 7 — Memory

- [ ] Host recall on every real user turn.
- [ ] Bounded top-k.
- [ ] Typed context contribution.
- [ ] Evidence labeled as data, not instructions.
- [ ] Gated ingest.
- [ ] Maximum ingests per turn.
- [ ] Vestige failure degradation.

## Gate 8 — Reliability/security

- [ ] Evaluation isolation appropriate to trust model.
- [ ] Secret leak tests.
- [ ] Snapshot excludes secrets.
- [ ] MCP/RLM capability restrictions.
- [ ] Failure injection suite.
- [ ] Daily-use benchmark against pi-default.

## Gate 9 — Optional Autolith adaptations

### Contributors
- [ ] registry;
- [ ] priority;
- [ ] lifetime;
- [ ] mandatory/advice classes;
- [ ] budget packing.

### RLM
- [ ] private frames;
- [ ] context descriptors;
- [ ] contract validation;
- [ ] shared hard budgets;
- [ ] trace IDs;
- [ ] no parent conversation pollution.

### Structured durable surfaces
- [ ] agenda;
- [ ] papercuts;
- [ ] evidence-backed writes;
- [ ] caps.

### Logical snapshots
- [ ] approved state only;
- [ ] no credentials;
- [ ] bounded retention;
- [ ] validated restore.

## Source references reviewed

### Pi-Lisptc

- `docs/00-problems-and-goals.md`
- `docs/03-architecture-overview.md`
- `docs/07-autolith-adaptation.md`
- `adr/0001-merge-prompt-not-replace.md`
- `adr/0003-validate-before-eval.md`
- `adr/0005-provider-modes.md`
- `adr/0006-profiles-lisp-mind-vs-pi-default.md`
- `adr/0007-context-contributors.md`
- `adr/0008-bounded-rlm-lisp-ops.md`
- `adr/0009-soft-generations-and-structured-surfaces.md`
- `plan/phase-00-baseline-profiles.md` through `plan/phase-12-soft-generations.md`

### lisptc

- `packages/interpreter/src/lisp.ts`
- `packages/interpreter/src/source.ts`
- `packages/interpreter/src/jobs.ts`
- `packages/interpreter/src/mcp.ts`
- `apps/pi/extension/lisp-repl.ts`
- `apps/pi/extension/system-prompt.ts`
- `packages/repl/src/repl.ts`
- `apps/lsp/src/server.ts`
- `apps/mcp/src/server.ts`

### Autolith

- `docs/architecture.org`
- `docs/rlm.org`
- `src/agent/memory-context.lisp`
- `src/resource/memory.lisp`
- `src/resource/agenda.lisp`
- `src/state/memories.lisp`
- `src/state/agendas.lisp`
- `src/self/tools.lisp`
- `src/inference/budget.lisp`
- `src/inference/frame.lisp`
- `src/inference/object.lisp`
- `src/inference/resource.lisp`

## Final implementation rule

When a feature can be implemented by reusing an existing authority, reuse it. New state stores, new transport stacks and duplicate registries should require an explicit ADR showing why the existing boundary cannot support the requirement.
