# Review-by-All — Fact-Check and Corrections

All 36 concrete factual claims from the five reviews, checked against cloned source code of lisptc (commit `b2ca6a59`) and autolith.

---

## 1. Gemini File Size Claims

| # | Claim | Verdict | Actual | Evidence |
|---|-------|---------|--------|----------|
| 1 | `lisp-repl.ts` is 15.6KB | **VERIFIED** | 15,624 bytes | `wc -c` |
| 2 | `system-prompt.ts` is 5.7KB | **VERIFIED** | 5,776 bytes | `wc -c` |
| 3 | `lisp.ts` is 73KB | **VERIFIED** | 73,286 bytes | `wc -c` |
| 4 | `mcp.ts` is 27KB | **VERIFIED** | 27,527 bytes | `wc -c` |
| 5 | `mcp-broker.ts` is 12KB | **CLOSE** | 12,896 bytes (~12.9KB) | Minor under-round |
| 6 | `mcp-oauth.ts` is 12KB | **VERIFIED** | 12,163 bytes | `wc -c` |
| 7 | `jobs.ts` is 13KB | **CLOSE** | 13,941 bytes (~13.9KB) | Minor under-round |
| 8 | `jobs-broker.ts` is 8KB | **VERIFIED** | 8,269 bytes | `wc -c` |
| 9 | `secrets.ts` is 8KB | **VERIFIED** | 8,020 bytes | `wc -c` |
| 10 | `grammar.ts` is 1KB | **REFUTED** | **147 bytes** (0.15KB) | File is just a 7-line `readFileSync` wrapper. Off by 7x. |
| 11 | `lisptc.gbnf` is 1KB | **VERIFIED** | 1,126 bytes | `wc -c` |

## 2. Gemini Interface Claims

| # | Claim | Verdict | Reality |
|---|-------|---------|----------|
| 12 | `LispSession` class with `eval`, `loadPrelude`, `saveSession`, `on` methods | **REFUTED** | No class named `LispSession` exists anywhere. Pi extension has `LispRepl` with `eval`, `reset`, `setConversationVars`, `takeHalted`. `MemoryRepl`/`AgentRepl` have `eval`, `reset`. None have `loadPrelude`, `saveSession`, or `on`. |
| 13 | `MCPBroker` class with `callTool`, `listServers` methods | **REFUTED** | No `MCPBroker` class exists. `mcp-broker.ts` exports standalone functions: `connect`, `callTool`, `listTools` (not `listServers`), `disconnect`, `login`, `authorize`, `logout`. |
| 14 | `SecretsStore` has `get`, `set` methods | **PARTIAL** | Interface has `get`, `set`, **and `list`** (omitted). `get` returns `{value, description} | undefined`, not `string | undefined`. `set` takes `Record<string, SecretSpec>`, not `(key, value)`. |
| 15 | `system-prompt.ts` returns `{ systemPrompt, tools }` | **REFUTED** | Module exports `SYSTEM_PROMPT: string`, `OUTPUT_TYPE`, `CODE_TYPE`, `MAX_STEPS`. The `before_agent_start` handler in `lisp-repl.ts` returns `{ systemPrompt: SYSTEM_PROMPT }` — a string value, no `tools` key. |

## 3. Pinning Claim

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 16 | lisptc pinned at `b2ca6a5946cfc054731ff0d882db17b1867a3d55` | **VERIFIED** | `git rev-parse HEAD` matches. Commit message: "Merge branch 'setup-app'". Shallow clone (1 commit). |

## 4. Sonnet Claims

| # | Claim | Verdict | Reality |
|---|-------|---------|----------|
| 17 | `src/prelude/mind-api.lisp` is 570 bytes | **MISATTRIBUTED** | The file exists in **Pi-Lisptc** repo (not lisptc). In lisptc upstream, no such file exists. Sonnet may have been checking the wrong repo. Actual size in Pi-Lisptc: ~500 bytes (all commented out). |
| 18 | lisptc is stateless (no persistence) | **REFUTED** | `mcp-oauth.ts` has `FileOAuthStore` persisting OAuth tokens to JSON via `writeFile`. `jobs-broker.ts` spills large replies to temp files. Lisptc has persistence — it's just scoped to OAuth tokens and temp spill, not application state. |
| 19 | lisptc has a single TypeScript backend provider model | **REFUTED** | Lisptc has **no** provider abstraction at all. The LLM provider is entirely Pi's concern. `lisp-repl.ts` calls `pi.registerProvider` — that's Pi's API, not lisptc's. |

## 5. GLM5p3 Self-Corrections

| # | Claim | Verdict | Reality |
|---|-------|---------|----------|
| 20 | SYSTEM_PROMPT doesn't include INTERPRETER_SOURCE | **VERIFIED** | Import on line 1 is dead code. `SYSTEM_PROMPT = POLICY` only. |
| 21 | `string-trim` bug: checks literal two-char strings | **VERIFIED** | Line 2375: `(or (equal c " ") (equal c "\\t") ...)` — `"\\t"` in JS template literal becomes the 2-char string `\t` (backslash+t). Single-char comparison never matches. |
| 22 | `repl.reset()` on ANY eval exception | **VERIFIED** | Lines 327-338: catch block unconditionally calls `repl.reset()`. |
| 23 | Session server uses `MemoryRepl` not `AgentRepl` | **VERIFIED** | `session-server.ts` L32 imports `MemoryRepl`, L179 instantiates it. |
| 24 | OAuth callback port fixed at 8909 (singleton) | **PARTIAL** | Default is 8909 but overridable via `LISPTC_OAUTH_CALLBACK_PORT` env var. Singleton pattern is correct. |
| 25 | `secretsExtension` doesn't auto-load .env in `AgentRepl` | **VERIFIED** | `repl.ts` L87 calls `secretsExtension()` with no options. `secrets.ts` L168: `if (options.envFile)` is false. |
| 26 | `packages/ai/src/index.ts` is completely empty | **REFUTED** | File has 4 lines of design comments describing future plans. Not executable code, but not empty. |
| 27 | No `finally` clause in try/catch | **REFUTED** | `finally` exists in: `lisp.ts` L1360 (import stack cleanup), `repl.ts` L119 (writer restore), `session-server.ts` L366 (socket cleanup), `cli.ts`. |

## 6. Cross-Review Consensus Claims

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 28 | Pi extension replaces system prompt and clears tools | **VERIFIED** | `lisp-repl.ts` L297: `pi.setActiveTools([])`, L322: `return { systemPrompt: SYSTEM_PROMPT }` |
| 29 | Provider hook unconditionally installs Fireworks grammar | **VERIFIED** | L272-280: adds `response_format: { type: "grammar", grammar: LISP_GRAMMAR }` to every request |
| 30 | Interpreter synchronous; MCP uses worker threads + Atomics.wait | **VERIFIED** | `jobs.ts` L145: `Atomics.wait(ctrl, 0, STATE_PENDING, timeoutMs)` |
| 31 | Autolith is SBCL-based with live-image persistence | **VERIFIED** | `active-image.lisp` L244: `sb-ext:save-lisp-and-die` |

## 7. Autolith-Specific Claims

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 32 | Context contribution advisory budget is 1500 tokens | **VERIFIED** | `context.lisp` L23: `*context-advice-token-budget*` = 1500 |
| 33 | Revision-gated resources (read returns revision, edit requires it) | **VERIFIED** | `protocol.lisp`: `resource-observation-revision` reader, `resource-revision-stale` condition, `resource.edit` takes `:base-revision` |
| 34 | 5-step self-modification protocol (journal→compile→check→probe→select) | **REFUTED** | Actual stages in `image-commits.lisp`: `:manifest`, `:history`, `:selection`, `:validation`, `:replay-probe`, `:publish`. No "compile" stage. The protocol names in AGENTS.md are a simplified summary, not the code's actual stage names. |
| 35 | context-cost-report.org identifies volatile context as top cache waste | **VERIFIED** | Finding #1: volatile context inside instructions; Finding #3: mutable session state in system prompt busts prefix |
| 36 | Tool lifecycle properties (persistence, barrier, execution-policy, child-safe, compact-visible) | **VERIFIED** | `registry.lisp`: `tool-conversation-persistence` L479, `tool-provider-round-trip-barrier-p` L488, `tool-execution-policy` L497, `tool-child-safe-p` L466, `tool-compact-result-visible-p` L527 |

---

## Impact Analysis

### Errors That Would Mislead Implementation

1. **Gemini's `LispSession`/`MCPBroker` interfaces (claims #12-13)**: If implemented, developers would create classes that don't match the actual API surface. The real classes are `AgentRepl`, `MemoryRepl`, and standalone functions in `mcp-broker.ts`.

2. **Gemini's `grammar.ts is 1KB` (claim #10)**: Trivial error, but indicates Gemini may not have actually read the file. At 147 bytes, `grammar.ts` is a trivial wrapper — understanding this affects estimates of how much "interpreter source" is actually language semantics vs infrastructure.

3. **Sonnet's "lisptc is stateless" (claim #18)**: This would lead to underestimating the complexity of the OAuth and temp-file persistence that already exists. Not application state, but still state that must be managed.

4. **GLM5p3's "no finally clause" (claim #27)**: Would lead to implementing unnecessary error-handling infrastructure for cleanup that already exists.

5. **All reviews' "5-step self-modification protocol" (claim #34)**: The actual Autolith code has 6 stages with different names. If Pi-Lisptc ever needs this pattern, referencing the correct stage names matters for accurate porting.

### Non-Impactful Errors

- File size under-rounds (claims #5, #7): Cosmetic.
- Sonnet's `mind-api.lisp` attribution (claim #17): File exists, just in wrong repo.
