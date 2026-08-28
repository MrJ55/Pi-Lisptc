# Review-by-GLM5p3 — Architecture Review

---

## 1. Architecture Assessment

### 1.1 The Three-Layer Model

Pi-Lisptc proposes three layers:

```
┌─────────────────────────────────────────────────┐
│  Pi (harness)                                    │
│  TUI, sessions, providers, extensions             │
│  buildSystemPrompt, opencode-go-cache             │
├─────────────────────────────────────────────────┤
│  lisptc (cortex)                                 │
│  In-process TypeScript Lisp interpreter           │
│  AgentRepl, MCP-in-image, forced Lisp channel     │
├─────────────────────────────────────────────────┤
│  Vestige (cabinet)                               │
│  SQLite-backed associative memory via MCP         │
│  Hybrid search, FSRS, smart_ingest               │
└─────────────────────────────────────────────────┘
```

**Assessment: The layer boundaries are correct but the integration surface between Pi and lisptc is underspecified.**

The plan describes *what* gets merged (prompt sections) but not *how* the Pi extension API is used at each hook point. Specific gaps:

- **`before_agent_start` contract:** Pi-Lisptc plans to return `{ systemPrompt: mergedPrompt }`. But Pi's actual API (observable from lisptc's extension) uses `pi.setActiveTools([])` in `session_start` and returns the prompt in `before_agent_start`. The plan conflates these two hooks. Phase 0's task list should explicitly separate: (a) tool clearing in `session_start`, (b) prompt assembly in `before_agent_start`.

- **`message_end` pipeline:** lisptc's extension uses this hook to eval code and drive the REPL loop with `triggerTurn: true`. Pi-Lisptc adds validation and Vestige recall/ingest to this pipeline but doesn't specify the ordering relative to eval. The 9-step pipeline in docs/03 puts recall (step 2) before model output (step 5), which is correct, but the epilogue (step 9) must happen *after* eval and *after* rendering — the plan doesn't specify which Pi hook this maps to.

- **`before_provider_request` composition:** lisptc injects Fireworks grammar here. Pi-Lisptc adds cache extension. But `opencode-go-cache` also uses this hook. The plan says "cache first" but doesn't describe how multiple extensions compose on the same hook. Pi's extension API may not support ordered composition.

### 1.2 Prompt Assembly

The merged prompt formula is:

```
customPrompt = piCodingCore + "\n\n" + lisptcChannel + "\n\n" + interpreterSource
```

**Critical issue: This puts volatile and stable content in the same cache-breaking region.**

Autolith's context-cost-report (finding #3) demonstrates quantitatively that mutable session state in the system prompt busts the entire prefix cache. Pi-Lisptc's `mind_active` summary (which changes every turn based on recall results) is concatenated directly into `customPrompt`, meaning the cache prefix is invalidated on every single user message.

**Revised architecture:**

```
System Prompt (stable, cacheable):
  piCodingCore + lisptcChannel + interpreterSource
  
Developer/User Message (volatile, behind history):
  mind_active summary + context contributions
```

The `mind_active` content should be injected as a trailing message (Pi may support this via `developer` message role or similar), not concatenated into the system prompt. This is the single highest-impact architectural change Pi-Lisptc can make.

### 1.3 Interpreter Source Bloat

The 11 files included in `INTERPRETER_SOURCE` total ~4,866+ lines. Several are irrelevant to the LLM:

| File | Lines | LLM Needs This? | Reason |
|------|-------|------------------|--------|
| `lisp.ts` | 2,386 | **Yes** | Core language semantics |
| `mcp.ts` | 877 | **Yes** | MCP calling conventions |
| `jobs.ts` | 422 | **Partial** | Understand `(await ...)` semantics, but internal SAB details are irrelevant |
| `secrets.ts` | 207 | **Yes** | Secret handling conventions |
| `mcp-broker.ts` | 365 | **No** | Worker-thread implementation; invisible to LLM |
| `mcp-oauth.ts` | ~200 | **No** | OAuth protocol; invisible to LLM |
| `jobs-broker.ts` | 223 | **No** | Worker-thread dispatch; invisible to LLM |
| `jobs-protocol.ts` | 54 | **No** | SAB wire protocol; invisible to LLM |
| `arith.ts` | ~100 | **Yes** | Arithmetic built-ins |
| `grammar.ts` | 3 | **Yes** | Grammar reference |
| `lisptc.gbnf` | 29 | **Yes** | Grammar definition |

**Savings from stripping irrelevant files:** ~842 lines (~2-3k tokens per turn). On a model with 128k context and 10-turn conversations, this saves 20-30k tokens.

**Recommendation:** Create a new export `INTERPRETER_SOURCE_LLM` in `source.ts` that includes only the files the LLM needs. The full `INTERPRETER_SOURCE` remains available for debugging.

### 1.4 REPL Reset Problem

The most dangerous architectural assumption is that `AgentRepl` provides a "living mind." In practice, the current Pi extension calls `repl.reset()` on any eval exception, which destroys all definitions.

**Concrete scenario:**
1. Turn 1: Agent defines `(defun analyze-module (path) ...)` — loaded into REPL
2. Turn 2: Agent calls `(analyze-module "src/foo.ts")` — MCP `fs/read` fails with network error
3. lisptc catches the exception → calls `repl.reset()`
4. Turn 3: `analyze-module` no longer exists. The "mind" has been lobotomized.

**Required fix (before Phase 2):** Modify the error handling to:
1. Catch the exception
2. Report it as structured error feedback to the model
3. **Preserve all prior definitions**
4. Only reset on explicit `(mind/reset!)` or detected image corruption

This is a ~10-line change in `lisp-repl.ts` with enormous impact.

### 1.5 The Cabinet-Cortex Bridge

The reification protocol is well-designed:

```lisp
(setq *mind/retrieved* hits)  ; REPLACE each turn
```

This is the right approach. Autolith's `memory-related-context` contributor does the same thing (top 6 results, ~1900 chars evidence). The replace-not-accumulate discipline (ADR-0004) prevents context growth.

**However, the bridge has no error handling specification:**
- What happens when Vestige is unreachable? The plan says "warn once, coding continues." But this means the agent operates with zero memory — potentially repeating mistakes from the same session.
- What happens when `smart_ingest` fails? The plan says "gated" but doesn't define the gate. Rate limit (3/turn) is specified but no queue or retry.
- What happens when the recall results are garbage? No relevance threshold is defined.

**Recommendation:** Define a `recall-quality-threshold` — if the best hit's score is below threshold, skip reification entirely and log the miss. This prevents injecting noise into the mind.

### 1.6 Profile Architecture

The two-profile design (ADR-0006) is sound:

```
pi-default:  stock Pi, no lisptc, normal tools
lisp-mind:  merged prompt, no outer tools, MCP-in-image, reify loop
```

**Gap:** No specification for profile switching mid-session. If a user starts in `lisp-mind` and hits an edge case where they need raw Pi tools, they must restart. Consider a `/profile pi-default` command that reloads the session.

**Gap:** No specification for how extensions besides `pi-lisptc` and `opencode-go-cache` compose with profiles. What if the user has a third Pi extension? Does it load in both profiles?

### 1.7 MCP-in-Image vs Outer Tools

The decision to move MCP inside the Lisp image (tools as Lisp functions) is correct. This eliminates the 30k+ token MCP schema cost and makes tools composable in Lisp.

**Risk:** The MCP bootstrap (Phase 4) loads servers at session start. If Vestige is slow to start, the entire session is blocked. Consider lazy loading: load Vestige MCP only on first recall call.

**Risk:** MCP tool results are synchronous (the main thread blocks via `Atomics.wait`). If a tool hangs, the entire agent freezes. The 30s timeout mitigates this but doesn't solve the UX problem — the user sees an unresponsive terminal.

### 1.8 Provider Constraint Architecture

The three-mode design is right in principle:

```
grammar mode:    Fireworks GBNF constrained decoding
json-tool mode:  Single tool wrapping a form string
retry mode:      No constraint, host validates, retry on failure
```

**The plan underspecifies the json-tool mode.** For providers that don't support grammar but have tool calling (e.g., OpenAI, Anthropic), the approach would be:
1. Define a single tool `eval_lisp_form` with schema `{ form: string }`
2. Constrain the model to output only tool calls (set `tool_choice: { type: "function", function: { name: "eval_lisp_form" } }`)
3. Extract the `form` string from the tool call

This is more reliable than free-text retry for providers with good tool-calling support. The plan should specify this mode explicitly.

---

## 2. Revised Architecture Recommendations

### 2.1 Prompt Layers (NEW — highest priority)

```
┌──────────────────────────────────────────────────────┐
│ LAYER 0: Stable System Prompt (changes rarely)        │
│   Pi coding role + guidelines                         │
│   lisptc channel rules (Lisp-only, halt, reply)        │
│   Interpreter source (LLM-relevant subset only)        │
│   → This entire layer is cacheable                     │
├──────────────────────────────────────────────────────┤
│ LAYER 1: Project Context (changes per workspace)       │
│   AGENTS.md, cwd, project invariants                   │
│   → Cached per workspace                               │
├──────────────────────────────────────────────────────┤
│ LAYER 2: Volatile Mind State (changes per turn)        │
│   mind_active summary (*mind/retrieved*, pins, prefs)  │
│   Context contributions (memories, recent ops)         │
│   → Injected as trailing developer message             │
│   → NEVER in system prompt prefix                      │
├──────────────────────────────────────────────────────┤
│ LAYER 3: Conversation History                         │
│   Standard message roles                               │
└──────────────────────────────────────────────────────┘
```

### 2.2 Error Recovery (revised)

```
Before eval:
  stripFences → parse → validate
  On failure: inject error, retry (up to N), NEVER eval

After eval:
  On success: return result normally
  On Lisp error (EvalException): 
    → report error to model as feedback
    → PRESERVE all definitions
    → do NOT call repl.reset()
  On catastrophic error (interpreter corruption):
    → call repl.reset()
    → log the event
    → attempt to reload from prelude/snapshot
```

### 2.3 Provider Modes (revised)

```
mode: grammar    → response_format: { type: "grammar", grammar: LISP_GRAMMAR }
                    Host still validates (defense in depth)
mode: tool-call  → Single tool: eval_lisp_form({ form: string })
                    tool_choice: forced
                    Most reliable for OpenAI/Anthropic
mode: retry      → No response_format
                    Host validates + retries
                    Fallback for providers without tool calling
```

### 2.4 Vestige Adapter Layer (NEW)

```
src/host/vestige-adapter.ts
  ├── recall(query, k, maxChars) → RecallHit[]
  │     Retries with exponential backoff
  │     Falls back to empty array on persistent failure
  │     Logs degradation events
  ├── ingest(entry: { content, tags, evidence }) → boolean
  │     Rate limited (3/turn, 30/minute)
  │     Queued on failure, replayed next turn
  └── version() → string
        Detects tool name changes across Vestige versions
```

This adapter isolates Pi-Lisptc from Vestige's API instability.

---

## 3. Unresolved Design Questions

| # | Question | Why It Matters | Suggested Resolution |
|---|----------|---------------|---------------------|
| D1 | How does Pi's `buildSystemPrompt` handle `customPrompt`? Does it still append project context? | The plan assumes it does (ADR-0001), but this must be verified against Pi's actual code. | Pin Pi SHA, read `buildSystemPrompt` source, document the exact contract. |
| D2 | Can multiple Pi extensions compose on `before_provider_request`? | Both `opencode-go-cache` and `pi-lisptc` need this hook. | Test with two extensions. If Pi doesn't support composition, implement a mediator. |
| D3 | What is the maximum acceptable latency for Vestige recall? | This blocks the user message pipeline. | Set p99 target: 200ms. If Vestige can't meet this, pre-fetch on prior turn completion. |
| D4 | How are secrets managed for Vestige MCP? | Vestige requires no API key (local), but other MCP servers do. | Document secret injection. Consider `(secret :vestige-api-key ...)` in prelude. |
| D5 | What happens when the interpreter source is updated (lisptc upgrade)? | The system prompt changes, busting cache, potentially changing language semantics. | Pin lisptc SHA. Define upgrade procedure: re-pin, re-measure cache, re-test. |
| D6 | Is `AgentRepl` safe for concurrent access? | Pi may call hooks from different threads. | Verify. If not, add a mutex in the Pi-Lisptc extension wrapper. |
| D7 | How does the mind survive Pi process restarts? | Pi is a long-running TUI but can crash. | Prelude save on session_end + reload on session_start (Phase 6). Verify this works. |