# Review-by-All — ADR Critique

ADR-by-ADR analysis incorporating amendments from all five reviews.

---

## ADR-0001: Merge Prompt, Not Replace — ✅ Strong

**All 5 reviews affirm.** Verified: `lisp-repl.ts` L322 returns only lisptc POLICY, destroying Pi's coding context.

**Amendments from other reviews:**
- **Sonnet:** Add merge algorithm specification (prepend/append/override sections). Add prompt hash/checksum for cache validation.
- **Luna:** Reference structured candidates/manifests. Prohibit direct prompt mutation.
- **Terra:** Extend validation to cover all prompt sections, not just the Lisp channel.
- **Gemini:** Pi portion is **foundational**; mind profile adds action-language contract but may NOT replace Pi's coding identity, AGENTS.md, cwd, or path guidance.
- **NEW (this synthesis):** Layer the merged prompt into stable (Layer 0) and volatile (Layer 2) regions. The volatile layer is delivered as a trailing message, not in the system prompt.

## ADR-0002: Vestige Cabinet, lisptc Cortex — ✅ Strong

**All 5 reviews affirm.** Correct separation of concerns.

**Amendments:**
- **Luna:** Vestige access must be mediated by the host, not embedded in the Lisp layer. Prevents memory authority coupling.
- **Terra:** Define cabinet API (read, write, query, compact) with GC policy.
- **Sonnet:** Define cabinet API (read, write, query, compact); add GC policy.
- **GLM5p3:** Define recall quality threshold; handle degraded Vestige (slow/low-quality results) separately from down Vestige.

## ADR-0003: Validate Before Eval — ✅ Essential

**All 5 reviews affirm.** Most universally endorsed ADR.

**Amendments:**
- **Luna:** Extend to persistence writes, tool dispatch, provider-output reuse, and materialization activation. Not just "parse Lisp," but validate the entire action chain.
- **Terra:** Define validation layers: syntax (parse), type (argument counts), effect (MCP calls), resource (token/time budgets).
- **Sonnet:** Define validation strategy document (ADR-0010 in Sonnet's proposal) with tooling choices.
- **GLM5p3:** Separate pre-eval validation (parse) from post-eval error recovery (preserve definitions).

## ADR-0004: Reify Replace, Not Accumulate — ✅ Strong (with caveat)

**4/5 reviews affirm.** Sonnet raises data-loss concern.

**Amendments:**
- **Sonnet:** Add snapshotting (keep N generations) and merge strategy for conflicts. The strict replace policy may lose useful context when recall quality varies turn-to-turn.
- **Luna:** Define replacement keys, atomicity, provenance, rollback, and retention for reification.
- **Terra:** Atomically replace active artifacts by replacement key. Retain superseded records according to retention policy.
- **GLM5p3:** Deduplication between `*mind/retrieved*` and `*mind/pins*` — overlapping content should not be duplicated.

## ADR-0005: Provider Modes — ✅ Good (needs interface)

**All 5 reviews affirm.** All identify missing interface.

**Amendments:**
- **Sonnet:** Define `IProvider` interface with capabilities (context window, rate limits, vision, tools, structured output, grammar).
- **Luna:** Replace hard-coded provider knowledge with capability negotiation from the actual selected provider/model.
- **GLM5p3:** Add `tool-call` mode (single `eval_lisp_form` tool, forced `tool_choice`) for OpenAI/Anthropic. This is the most reliable constrained-output approach for these providers.
- **Terra:** Require capability matrix and fallback semantics. Provider swap changes only adapter/config, not core behavior.
- **Gemini:** Specific capability registry examples: `fireworks/llama-3.1-8b` → grammar; `openai/gpt-4o` → validate-retry; `anthropic/claude-3.5-sonnet` → validate-retry.

## ADR-0006: Two Profiles — ✅ Strong

**All 5 reviews affirm.**

**Amendments:**
- **Terra:** Define profile schema with `persistencePolicy` (off/ephemeral/durable) and `approvalPolicy` (requiredFor array).
- **Sonnet:** Define profile switching API (not just launch scripts).
- **GLM5p3:** No mid-session switching for v1. Document this limitation.

## ADR-0007: Context Contributors — ✅ Good (underspecified)

**All 5 reviews agree this is the right pattern for phase 9.** All identify missing specification.

**Amendments from Terra (most detailed):**
- Add versioning, provenance, sensitivity, budgets, deterministic order, isolation.
- Direct prompt mutation is prohibited; only the assembler may write final context.
- The contributor API should be independent of underlying memory implementation.

**Amendments from Luna:**
- Contributions carry provenance and cost metadata: `Contribution {content, source, priority, token_cost, ttl}`.

**Budget (from Autolith, verified):** Mandatory always included (8k char hard cap). Advisory competes for ~1,500 token budget.

## ADR-0008: Bounded RLM — ✅ Good (correctly deferred)

**All 5 reviews agree on deferral.** GLM5p3 and Luna add blocking concerns.

**New concern (GLM5p3):** lisptc's `Atomics.wait` blocks the main thread. RLM sub-requests would need to bypass the interpreter's jobs runtime and make provider calls directly from the host. This creates a architectural split between normal eval (through interpreter) and RLM eval (bypassing interpreter).

## ADR-0009: Soft Generations — ✅ Good

**All 5 reviews affirm.**

**Amendments:**
- **Terra:** Generated surfaces are non-authoritative and cannot bypass capability/materialization policy.
- **Gemini:** Restore is load-into-REPL, not process reboot. Explicit rejection of Autolith recovery-image boot loops.

## Proposed New ADRs (Consolidated from All Reviews)

### ADR-0010: Prompt Cache Architecture (NEW — from GLM5p3 + Autolith evidence)
Stable system prompt (Layer 0) + volatile mind state (Layer 2 trailing message). Never mix volatile state into cache-breaking prefix.

### ADR-0011: Host/Runtime Boundary (NEW — from Luna + Terra)
Interpreter must not import Pi-specific prompt, Vestige, UX, or profile policy. Dependency direction: prelude → host API → adapters.

### ADR-0012: Error Recovery Semantics (NEW — from GLM5p3 + Luna)
`EvalException`: preserve definitions, report error, do NOT reset. Catastrophic corruption: reset + prelude reload. Interpreter reset as rollback is rejected.

### ADR-0013: Interpreter Source Optimization (NEW — from GLM5p3)
Create `INTERPRETER_SOURCE_LLM` excluding mcp-broker.ts, mcp-oauth.ts, jobs-broker.ts, jobs-protocol.ts (~842 lines saved).

### ADR-0014: Validation Strategy (from Sonnet + Luna + Terra)
Layers: syntax (parse), type (argument counts), effect (MCP schema), resource (token/time budgets). Tooling: lisptc reader for syntax.

### ADR-0015: Persistence Schema (from Sonnet + Terra)
Schema versioning, migration functions, write-ahead logging. Start design in Phase 3 (per Sonnet's bottleneck analysis).

### ADR-0016: Capability Grants (from Terra)
Adapters callable only through named requests passing schemas, profile grants, allowlists, approval policy, budgets. `CapabilityResult<T>` discriminated union with DENIED/INVALID/BUDGET/UNAVAILABLE/FAILED/CANCELLED.

### ADR-0017: Audit Manifest (from Terra + Gemini)
Every turn records: turnId, timestamp, profile, provider, mode, recallQuery, recallResults, reificationForm, evalResult, mcpCalls, smartIngestDecision.

### ADR-0018: Minimal Bootstrap Allowlist (from Gemini + Terra)
In lisp-mind profile, only `opencode-go-cache` is approved as an outer tool. All other tools go through MCP-in-image.

### ADR-0019: Memory Safety Pipeline (from Terra + Gemini)
8-stage reification: Vestige record → schema validation → scope/sensitivity filter → ranking/budget → data-only Lisp serializer → parse to AST → allowlist validation → eval.

### ADR-0020: Test Strategy (from Terra + Gemini + GLM5p3)
6-level pyramid: unit, contract, integration, differential (fork vs upstream), adversarial, E2E. Coverage targets: 95% provider-policy, 90% lisp-repl, 85% vestige, 80% system-prompt.