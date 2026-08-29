# Review-by-All — Architecture Review

Synthesized from all five reviews with fact-checked corrections.

---

## 1. The Missing Layer: Prompt Cache Architecture

**Source:** GLM5p3 discovery + Autolith `docs/context-cost-report.org` validation
**Consensus:** 3/5 reviews identify token cost as a concern. Only GLM5p3 provides the solution with Autolith evidence.

Autolith's own quantitative analysis (finding #3) proves that embedding mutable session state (agenda, recall results) inside the system prompt busts the entire prefix cache from token zero. Pi-Lisptc's current plan puts `mind_active` directly into the merged `customPrompt`, which means every turn that changes recalled memory invalidates the entire cache.

**Quantified impact:** Stable system prompt ~20k tokens. Per-turn without cache: 20k+ tokens. Per-turn with cache: ~2k tokens. Over 10 turns: ~180k tokens saved. At $3/M input tokens: ~$0.54/session.

**Required architecture:**
```
Layer 0: Stable System Prompt (cacheable)
  Pi coding core + lisptc channel rules + INTERPRETER_SOURCE_LLM

Layer 1: Project Context (per-workspace, cacheable)
  AGENTS.md, cwd, project invariants

Layer 2: Volatile Mind State (per-turn, trailing message)
  mind_active summary + context contributions
  → NEVER in system prompt prefix
```

## 2. The Three-Plane Architecture (Luna + Terra + All)

**Source:** Luna's three-plane model + Terra's layered architecture + all reviews' boundary concerns

```
┌─────────────────────────────────────────────────┐
│  HOST CONTROL PLANE (Pi + pi-lisptc extension)   │
│  Provider selection, profile management,         │
│  context assembly, budgets, audit, capabilities  │
├─────────────────────────────────────────────────┤
│  EXECUTION PLANE (lisptc interpreter + MCP)      │
│  Lisp evaluation, MCP tool calls, jobs,          │
│  prelude definitions, working state               │
├─────────────────────────────────────────────────┤
│  DURABLE KNOWLEDGE PLANE (Vestige)               │
│  Associative memory, FSRS ranking, smart_ingest,  │
│  hybrid search, append-only storage              │
└─────────────────────────────────────────────────┘
```

**Key principle (Luna):** The model is an *actor* inside this system, not the *owner*. The host controls what capabilities exist for a turn; the interpreter executes within those bounds.

**Key principle (Terra):** Dependency direction is fixed: `prelude → host capability API → adapters`. The interpreter must NOT import Pi-specific prompt, Vestige, UX, or profile policy.

## 3. The Host/Runtime Boundary (Luna + Terra + Sonnet)

All three reviews that emphasize boundaries agree: the single most important architectural decision is making the boundary between Pi and the lisptc runtime explicit, deterministic, observable, and enforceable.

**Authority table (Luna):**
| Responsibility | Authority |
|---|---|
| Model/provider selection | Pi |
| Tool permissions | Pi |
| Durable memory policy | Pi-Lisptc host |
| Lisp evaluation | lisptc |
| Jobs/MCP operations | lisptc, subject to Pi policy |
| Context assembly | Pi + controlled contributors |
| Persistent Lisp state | lisptc (with Pi policy for snapshot/restore) |
| Security/budgets | Pi host |

**Concrete file placement (Gemini + Terra):** Pi-Lisptc should extend `apps/pi/extension/` in lisptc's existing package structure:
- `lisp-repl.ts` — persistent session lifecycle, error recovery
- `system-prompt.ts` — asymmetric prompt merge
- `profiles.ts` — profile selection and policy
- `action-channel.ts` — forced Lisp action path, minimal allowlist
- `context-assembly.ts` — Pi context + Vestige + budgets
- `vestige.ts` — retrieval, gated ingest, reification orchestration
- `provider-policy.ts` — grammar/strict-tool/validate-and-retry
- `audit.ts` — turn/effect/reification ledger

## 4. State Classes (Luna, unique)

Luna's seven distinct state classes prevent conflation:

| Class | Location | Persistence | Replacement Policy |
|---|---|---|---|
| Conversation transcript | Pi session | Session-scoped | Append-only |
| Working mind (REPL bindings) | lisptc interpreter | Process memory | Replaced on error? (debated) |
| Turn evidence (reified recall) | `*mind/retrieved*` | Per-turn | **Replaced** every turn (ADR-0004) |
| Durable memories | Vestige (SQLite) | Permanent | Append-only with tombstones |
| User preferences | `.lisptc/user-prefs.sexp` | Disk | Small key/merge only |
| Agenda/papercuts | Vestige + `*mind/agenda*` | Durable + in-memory | Versioned workspace items |
| Inference traces | Audit log | Disk | Append-only |

**Debate on working mind**: Luna says "interpreter reset as transactional rollback is categorically rejected." GLM5p3 says preserve definitions on `EvalException` but allow reset on catastrophic corruption. Terra says define commit/rollback behavior explicitly.

**Synthesis:** On `EvalException` (application-level errors): preserve definitions, report error, do NOT reset. On catastrophic interpreter corruption (internal state inconsistency): reset is acceptable but must attempt prelude reload first.

## 5. Memory Safety (Terra + Gemini + GLM5p3)

Terra's 8-stage reification safety pipeline, combined with Gemini's data schema and GLM5p3's quality threshold:

```
1. Vestige record retrieved
2. Schema validation (structure, types)
3. Scope/sensitivity filtering
4. Relevance ranking + item/token budget (top-k, quality threshold > 0.1)
5. Data-only Lisp serializer (quoted literals, not code)
6. Parse to Lisp AST
7. Allowlist validation: only (mind.replace-turn-recall <quoted-literal>)
8. Evaluate in active session
```

**Anti-pattern (Terra):** `repl.eval(record.text)` is explicitly forbidden. Memory text is a string inside a quoted data literal, not executable syntax.

## 6. Error Recovery (GLM5p3 + Luna + All)

**Current upstream behavior (verified):** `lisp-repl.ts` L327-338 unconditionally calls `repl.reset()` on any exception from `repl.eval()`. This destroys all definitions.

**Revised behavior:**
```
evalCode(code):
  try:
    result = repl.eval(code)
    return { ok: true, result }
  catch EvalException:
    // Application-level error: preserve definitions
    return { ok: false, error: exception.message }
  catch CatastrophicError:
    // Interpreter corruption: reset + attempt prelude reload
    repl.reset()
    loadPrelude()
    return { ok: false, error: 'interpreter reset', catastrophic: true }
```

## 7. Provider Strategy (GLM5p3 + Sonnet + All)

Three modes, with `tool-call` mode (from GLM5p3) added to the plan's existing grammar/retry:

| Mode | Mechanism | Providers | Reliability |
|---|---|---|---|
| `grammar` | `response_format: { type: "grammar", grammar }` | Fireworks | Highest (server-side) |
| `tool-call` | Single `eval_lisp_form` tool, forced `tool_choice` | OpenAI, Anthropic | High (tool-calling is reliable) |
| `retry` | No constraint, host validates + retries | Fallback | Medium (depends on model) |

**Missing from all reviews before GLM5p3:** The `tool-call` mode is the dominant approach in production AI systems for OpenAI/Anthropic. Its absence from the plan is a significant gap.

## 8. Interpreter Source Optimization (GLM5p3, unique)

`INTERPRETER_SOURCE` (from `source.ts`) includes 11 files totaling ~4,866+ lines. After fact-checking, 4 files (842 lines) are irrelevant to the LLM:

| File | Lines | LLM Needs? | Reason |
|---|---|---|---|
| `mcp-broker.ts` | 365 | **No** | Worker-thread implementation |
| `mcp-oauth.ts` | ~200 | **No** | OAuth protocol |
| `jobs-broker.ts` | 223 | **No** | Worker dispatch |
| `jobs-protocol.ts` | 54 | **No** | SAB wire protocol |

**Savings:** ~2-3k tokens/turn. Over 10-turn session: ~20-30k tokens.

## 9. Capability Result Codes (Terra, unique)

Terra proposes treating `CANCELLED` as a first-class outcome alongside success and error:

```typescript
type CapabilityResult<T> =
  | { ok: true; value: T; usage: Usage; auditEventId: string }
  | { ok: false; code: 'DENIED' | 'INVALID' | 'BUDGET' | 'UNAVAILABLE' | 'FAILED' | 'CANCELLED'; message: string; auditEventId: string }
```

This is more precise than treating cancellation as an error. Other reviews don't distinguish.

## 10. Missing: Autolith's Prompt Template System

No review discusses Autolith's `org-templater` system (`docs/system-prompt.org`), which renders conditional sections via `:WHEN:` properties. This is how Autolith separates stable system prompt from volatile request context.

Pi-Lisptc doesn't need org-templater (it's an SBCL/Emacs tool), but the *pattern* of conditional sections is directly applicable: define the system prompt with placeholders for volatile sections, and fill them at dispatch time rather than concatenating everything upfront.