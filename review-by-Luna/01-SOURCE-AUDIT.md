# Source Audit — Pi-Lisptc, lisptc, Autolith

## 1. Audit scope

The review examined the actual repository trees and implementation files rather than relying on README summaries. Key inspected boundaries include:

- Pi-Lisptc: goals, architecture, ADRs, phases 0–12, prelude, scripts.
- lisptc: interpreter core, `source.ts`, Pi extension, MCP layer, jobs layer, REPL/LSP/application layout.
- Autolith: architecture, memory-context contributor, RLM design, self-mutation boundary, state separation.

## 2. Upstream lisptc findings

### 2.1 The interpreter is a real persistent execution environment

`packages/interpreter/src/lisp.ts` contains the actual reader/evaluator, lexical environment representation, closures, macros, built-ins, exceptions, symbols and argument handling. This is not merely a parser wrapper. Pi-Lisptc can therefore legitimately use it as a persistent working cortex.

Important implication: the fork should avoid wrapping the interpreter in a second pseudo-language or duplicating its state model. Add host services around it.

### 2.2 The interpreter is synchronous

`packages/interpreter/src/jobs.ts` explicitly describes the interpreter as fully synchronous. Asynchronous work is factored into a `JobsRuntime`; the bundled implementation uses `worker_threads`, SharedArrayBuffer and `Atomics.wait` to bridge synchronous Lisp calls to worker work.

This is clever and appropriate for a synchronous Lisp, but it creates a hard architectural constraint: the host must own timeout, worker lifecycle, shutdown and cancellation policy. Do not expose arbitrary worker lifecycle decisions as ordinary application code.

### 2.3 MCP is already substantially implemented

`packages/interpreter/src/mcp.ts` is more capable than a simple tool adapter. It supports server configuration, remote URL and local command servers, OAuth parameters, conversion between Lisp and JSON, schema checks, server lifecycle, and tool installation as ordinary globals such as `server/tool`.

Therefore Pi-Lisptc should **reuse this capability** rather than build a parallel MCP abstraction. The new code should mainly provide policy, bootstrap, failure handling and host integration.

### 2.4 The current Pi extension has exactly the problems the plan identifies

`apps/pi/extension/lisp-repl.ts`:

- calls `pi.setActiveTools([])`;
- replaces the system prompt with `SYSTEM_PROMPT`;
- installs a fixed Fireworks provider/model list;
- unconditionally writes a grammar `response_format` in `before_provider_request`;
- evaluates assistant text directly in `message_end`;
- resets the whole REPL after an evaluation exception;
- drives a multi-step loop using `triggerTurn` and a hard step cap.

The fork's decision to correct these is therefore source-grounded, not speculative.

### 2.5 Prompt source is deliberately enormous

`packages/interpreter/src/source.ts` constructs `INTERPRETER_SOURCE` by reading `arith.ts`, `lisp.ts`, `grammar.ts`, `secrets.ts`, `jobs.ts`, `jobs-protocol.ts`, `jobs-broker.ts`, `mcp.ts`, `mcp-broker.ts`, `mcp-oauth.ts`, and the grammar file, then wrapping each as a source section.

This is a sound bootstrap mechanism for semantic accuracy, but it is also the dominant context-cost risk. The fork should preserve it initially for correctness, then move toward a stable cached language contract plus on-demand source references. Do not prematurely rewrite the interpreter description from memory.

### 2.6 Conversation visibility is useful but dangerous as a permanent primitive

The Pi extension creates read-only `conversation`, `user-messages`, and `assistant-messages` globals by scanning the Pi session manager before evaluation. This is a valuable capability for an agent that needs continuity, but it conflates transcript access with working memory.

Recommendation: retain conversation access as a controlled host-provided read-only resource. Do not copy the entire transcript into durable mind state or into every prompt by default.

## 3. Pi-Lisptc plan findings

The planning repository is unusually disciplined for a project at this stage. The ADRs explicitly settle prompt merging, memory/cortex separation, validation before evaluation, replacement semantics for retrieval, provider modes, profiles, contributors, bounded RLM and soft generations.

The strongest architectural principle is `cabinet != cortex`: Vestige is durable associative memory while lisptc is live working state. Keep this distinction.

The weakest part is that the plan jumps from individual features to a functioning system without first specifying the lifecycle contract connecting the host and interpreter. That omission will become expensive around MCP, retries, snapshots, and RLM.

## 4. Autolith findings

### 4.1 Context contributors are more important than RLM for this project

Autolith's `memory-context.lisp` has explicit result, evidence and excerpt limits and returns a context contribution with priority and turn lifetime. It also tells the model that excerpts are potentially stale data and should be read as data rather than instructions.

Pi-Lisptc's Phase 9 should adopt this pattern, but the design can be pulled earlier: Phase 7 should already produce a typed contribution envelope, even if only one built-in contributor exists.

### 4.2 RLM's strongest contribution is containment, not recursion

Autolith's RLM design defines private inference frames, explicit context views, contracts, shared budgets, trace identifiers and a rule that child frames never inherit the parent conversation or unrestricted capabilities.

The key lesson for Pi-Lisptc is therefore: **if RLM is added, isolate the subtask context and capability surface first; recursion is secondary.**

### 4.3 Budget accounting is materially more sophisticated than the current Pi-Lisptc plan

Autolith reserves output-token tranches atomically, shares counters across recursive children, caps depth, and turns exhaustion into an explicit condition. Pi-Lisptc's Phase 10 mentions calls/tokens/depth but currently reads more like a feature checklist than an accounting model.

Before implementation, define whether budgets are hard reservations, post-hoc accounting, or both. Prefer hard call/depth limits and conservative output reservations; record actual usage separately.

### 4.4 State separation is highly transferable

Autolith separates conversations, memories, agendas, papercuts and input vault state. Pi-Lisptc should adopt the conceptual separation without adopting Autolith's `sexp-store` or SBCL image architecture.

### 4.5 Live self-mutation should remain outside core

Autolith's `self.*` machinery has mutation journals, restarts, definition signatures, exploratory state and private image-history commits. This is far beyond what a Pi extension should own. Pi-Lisptc is correct to reject it as a core requirement.

## 5. Architectural source-of-truth conclusions

1. **lisptc is the execution substrate.** Do not fork its semantics unnecessarily.
2. **Pi is the agent host and provider/session owner.** Do not let the Lisp image become a second Pi.
3. **Vestige is the durable memory authority.** Do not make the REPL a database.
4. **The host is the policy authority.** Prompt instructions are advisory; lifecycle, capability, budgets and durable writes are enforced outside model-authored Lisp.
5. **Autolith is a design-pattern donor.** Copy bounded interfaces and invariants, not its runtime architecture.

## 6. Source-level issues to carry into implementation

| Issue | Evidence | Severity | Recommendation |
|---|---|---:|---|
| Prompt replacement | `apps/pi/extension/system-prompt.ts`, `lisp-repl.ts` | Critical | Merge with Pi system-prompt contract |
| Unconditional grammar | `lisp-repl.ts` | Critical | Provider/model capability dispatch |
| Fixed provider registry | `lisp-repl.ts` | High | Do not replace Pi model registry; add constraint adapter |
| Eval reset on throw | `lisp-repl.ts` | Critical | Parse first; isolate semantic failure; sandbox later |
| Huge prompt source | `source.ts` | High | Keep initially; cache/version and later compact |
| Synchronous interpreter | `jobs.ts` | High | Host lifecycle/timeout contract |
| MCP worker architecture | `mcp.ts` + `jobs.ts` | High | Reuse, don't duplicate |
| Transcript as Lisp globals | `lisp-repl.ts` | Medium | Read-only, bounded, not durable by default |
| Context contributors absent from core | Autolith `memory-context.lisp` | Medium | Introduce typed envelope in Phase 7 |
| RLM budget underspecified | Autolith `docs/rlm.org` vs Phase 10 | High | Define accounting semantics before code |
