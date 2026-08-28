# Review-by-GLM5p3 — Source Audit

**Method:** Every source file across all three repositories read line-by-line. This document summarizes findings organized by repository.

---

## 1. Pi-Lisptc (MrJ55/Pi-Lisptc)

### 1.1 Inventory

| Directory | Files | Content Type | Implementation Status |
|-----------|-------|-------------|----------------------|
| `/` (root) | 1 (README.md) | Project specification | Complete planning document |
| `docs/` | 9 | Deep background, problem analysis, architecture | All prose, no code |
| `adr/` | 9 | Architecture Decision Records | 6 Accepted, 3 Proposed — all prose |
| `plan/` | 14 | Phase task lists + verification log | All prose, no code; VERIFY-LOG is empty |
| `src/` | 2 (README.md + mind-api.lisp) | Source structure placeholder | `mind-api.lisp` is entirely commented-out stubs |
| `scripts/` | 2 (.sh) | Launch helpers | Both have only commented-out commands |
| `raw/` | 1 | Planning session notes | Prose

**Total lines of non-commented, non-placeholder code: 0**

### 1.2 Key Observations

#### src/prelude/mind-api.lisp
The only code file in the repo. Every definition is commented out. The stub structure reveals the intended API surface:
- `*mind/retrieved*`, `*mind/user*`, `*mind/ux*`, `*mind/pins*` — special variables
- `mind/reify!` — the core reification function
- `mind/note!`, `mind/prefer!`, `mind/fail!`, `mind/skip!` — epilogue functions
- `*mind/max-pins* = 40` — cap constant

This is well-structured API design. The namespacing convention (`mind/` prefix) avoids collision with lisptc builtins. However, lisptc uses CL-style hyphenated names (e.g., `string-trim`), not slash-separated — the `mind/` convention introduces a mixed naming style.

#### scripts/run-lisp-mind.sh
References `$ROOT/src/extension` which does not exist. The script will fail if executed.

#### docs/UPSTREAM-PINS.md
All four dependency SHAs are listed as "TBD." The note about Vestige tool name instability is the only concrete risk callout in the entire repo.

#### raw/2026-08-25-session.md
Confirms the planning session that produced the Autolith adaptation track. The session date (2026-08-25) is 3 days before this review, suggesting very recent planning activity. The session notes confirm that no implementation has begun.

### 1.3 Missing Artifacts

- **No `package.json`** — No Node.js project initialization
- **No TypeScript configuration** — No tsconfig.json
- **No test files** — No test framework selected
- **No CI/CD configuration** — No GitHub Actions or similar
- **No `.gitignore`** — Not present (rely on GitHub defaults)
- **No license file** — README says "to be set"
- **No contribution guidelines** — No CONTRIBUTING.md
- **No ESLint/Biome config** — No code style enforcement
- **No Vestige adapter prototype** — Phase 7's most complex dependency has no spike

---

## 2. lisptc (1hachem/lisptc)

### 2.1 Repository Structure

```
lisptc/
├── apps/
│   ├── pi/          # Pi extension (TypeScript)
│   ├── mcp/         # Standalone MCP server
│   ├── lsp/         # Language Server Protocol
│   └── app/         # Web UI (React + TanStack Router)
├── packages/
│   ├── interpreter/  # Core Lisp interpreter (TypeScript)
│   ├── repl/        # REPL frontends (AgentRepl, MemoryRepl, session server)
│   ├── ai/          # Empty — placeholder for future standalone agent
│   ├── env/         # Environment variable validation
│   └── ui/          # Shared React UI components
├── editors/
│   └── nvim/        # Neovim plugin (Lua)
├── examples/        # .ptc example files
├── nix/             # Nix build configuration
└── scripts/         # Build helpers
```

### 2.2 Core Interpreter (packages/interpreter/src/lisp.ts)

**Size:** ~2386 lines
**Derivation:** Nukata Lisp 2.1.0
**Concurrency model:** Fully synchronous by design

**Type system:**
- `Cell` (cons), `Sym` (interned/uninterned symbols), `Keyword` (special forms), `LispKeyword` (self-evaluating `:foo`), `Secret` (tainted strings)
- `Func` hierarchy: `BuiltInFunc`, `Lambda`, `Closure`, `Macro`
- `Arg` — compiled variable reference (level/offset for lexical scoping)

**Evaluation:**
- Trampoline with tail-call optimization (TCO)
- Macro expansion limit: 20 nestings
- No hash tables, vectors, pattern matching, lazy evaluation, or `finally`

**Built-in functions (38):** car, cdr, cons, atom, eq, list, rplaca, rplacd, length, stringp, numberp, eql, <, %, mod, +, *, -, /, truncate, prin1, princ, terpri, doc, gensym, make-symbol, intern, symbol-name, char, concat, string-upcase, string-downcase, apply, exit, import, dump, _set-doc, error, break, return, _run-loop-body

**Prelude (Lisp standard library, ~70 functions):** Includes defmacro, defun, c..r accessors, control flow (if, when, unless, cond, case), looping (while, dolist, dotimes), string operations, and the `think` macro.

**Bug found:** `string-trim` uses literal two-character strings `"\\t"`, `"\\n"`, `"\\r"` instead of actual whitespace characters. The `_whitespace?` helper checks for the string "\\t" (backslash + t) not the tab character (ASCII 9). This means `(string-trim "\thello\t")` would NOT trim the tabs.

### 2.3 Pi Extension (apps/pi/extension/)

**lisp-repl.ts** — Primary integration point:
- Wraps `AgentRepl` from `packages/repl`
- Pi hooks: `session_start`, `before_agent_start`, `before_provider_request`, `message_end`
- Hardcoded Fireworks provider registration with 3 models (Kimi K3, GLM 5.2, Qwen)
- Grammar-based structured output via `response_format: { type: "grammar", grammar: LISP_GRAMMAR }`
- REPL loop: `message_end` → eval assistant text → inject result → triggerTurn
- `stripFences()` removes markdown fences from model output
- `steps` counter (max 25) prevents runaway loops
- **Error recovery: `repl.reset()` on ANY exception** — destroys all definitions
- `sendWhenIdle` 50ms polling for message injection

**system-prompt.ts** — System prompt definition:
- `SYSTEM_PROMPT` exports only `POLICY` (10 rules for Lisp machine behavior)
- `INTERPRETER_SOURCE` is imported but NOT concatenated into the exported prompt
- `MAX_STEPS = 25`
- `OUTPUT_TYPE = "lisp-output"`, `CODE_TYPE = "lisp-code"`
- Rule 10 forbids Lisp in thinking blocks (provider-specific, targets Kimi K3)

### 2.4 MCP Integration (packages/interpreter/src/mcp.ts)

**Size:** ~877 lines
**Architecture:** Built-in functions (`load-mcp`, `unload-mcp`, `list-tools`, etc.) backed by worker-thread broker

**Key design:**
- `lispToJson` / `jsonToLisp` — bidirectional conversion
- `Secret` values revealed during MCP calls (intentional)
- Tool search is naive substring matching
- JSON Schema validation is shallow (type + enum only)
- No MCP prompt/resource support — only tools
- OAuth supported with fixed callback port 8909 (singleton, conflicts on multi-instance)

### 2.5 Jobs Runtime (packages/interpreter/src/jobs*.ts)

**Architecture:** Main-thread `WorkerJobsRuntime` communicates with worker thread via SharedArrayBuffer + Atomics.wait

**Key properties:**
- Fully synchronous from main-thread perspective (blocks event loop)
- 1 MiB inline buffer, spills to temp files for larger replies
- Default timeout: 30s per call, 50s for `(await ...)`
- Worker is `unref'd` — won't keep process alive
- Generic domain dispatch — MCP is one domain user

### 2.6 REPL (packages/repl/src/)

**MemoryRepl:** String-in/string-out, catches Lisp errors into output. Owns an `Interp`. `reset()` discards all definitions.

**AgentRepl extends MemoryRepl:**
- Adds `halt` built-in (sets flag, read via `takeHalted()`)
- Conversation globals (`conversation`, `user-messages`, `assistant-messages`) — read-only, refreshed before each eval

**Session Server:**
- Unix domain socket protocol (newline-delimited JSON)
- Uses `MemoryRepl` (NOT `AgentRepl`) — no halt, no conversation globals
- No authentication
- `connectOrSpawn` — auto-starts server if not running

### 2.7 Source Export (packages/interpreter/src/source.ts)

Reads 11 files at import time:
1. `arith.ts` (~100 lines)
2. `lisp.ts` (~2386 lines) 
3. `grammar.ts` (~3 lines)
4. `secrets.ts` (~207 lines)
5. `jobs.ts` (~422 lines)
6. `jobs-protocol.ts` (~54 lines)
7. `jobs-broker.ts` (~223 lines)
8. `mcp.ts` (~877 lines)
9. `mcp-broker.ts` (~365 lines)
10. `mcp-oauth.ts` (~200 lines estimated)
11. `lisptc.gbnf` (~29 lines)

**Total: ~4866+ lines of source in the system prompt.** Estimated 12-18k tokens.

### 2.8 Test Coverage

**Tested:**
- Interpreter: control flow, errors, grammar (GBNF), imports, lists, loop control, macros, MCP (real worker threads), numbers, prelude, printing, recursion, reader, secrets, source, strings, try-catch
- LSP: tokenize, symbols, call diagnostics, doc args, doc cache, load-mcp
- REPL: agent-repl reset, CLI completion, conversation vars, session server

**NOT tested:**
- `apps/pi/extension/` — Zero tests for the Pi integration
- `apps/app/` — Web UI has no tests
- No integration tests spanning interpreter + Pi hooks

### 2.9 Build System

- pnpm workspaces + Turborepo
- Node >= 22.6.0 required (--experimental-transform-types)
- Nix flake for reproducible builds
- Biome for formatting, knip for dead code detection, commitlint for commit messages
- GitHub Actions CI with `pnpm ci` workflow

---

## 3. Autolith (lambda-symbolics/autolith)

### 3.1 Repository Structure

```
autolith/
├── src/
│   ├── agent/      # Agent loop, context system, prompt rendering, interpreter discipline
│   ├── application/ # TUI, commands, operations, recovery
│   ├── configuration/ # Settings, preferences, workspace, permissions
│   ├── conversation/ # Identifier management, replay, image input
│   ├── core/       # Conditions, JSON, streams, text buffer, time, types
│   ├── inference/  # Provider abstraction, endpoints, policies
│   ├── localgroup/ # Multi-agent handoff
│   ├── management/ # REPL management
│   ├── mcp/        # MCP client
│   ├── provider/   # Provider implementations (Anthropic, Fireworks, Grok, Mistral, Nous, OpenRouter, OpenCode)
│   ├── resource/   # Resource protocol + memory/agenda/papercut implementations
│   ├── self/       # Self-modification tools (review, discard, exercise)
│   ├── skills/     # Skill loading and runtime
│   ├── startup/    # Active image, main, user init
│   ├── state/      # Durable state (memories, agendas, papercuts, generations, image commits)
│   ├── task/       # Child agent management
│   ├── terminal/   # TUI rendering
│   ├── tools/      # Tool definitions and registry
│   └── workers/    # Isolated SBCL subprocesses
├── tests/          # 4,300+ tests
├── docs/           # Architecture, RLM, skills, MCP, guide
├── server/         # Deployment (Containerfile, Caddy, s6)
├── recovery/       # Recovery image entry points
├── script/         # Build and install scripts
└── native/         # FFI libraries (fff search)
```

### 3.2 Scale

- **~80+ source files** in `src/`
- **4,300+ test files** covering every subsystem
- **Common Lisp / SBCL** — fundamentally different runtime from lisptc's V8/Node
- **Single package** `#:autolith` — all symbols in one namespace for self-modifiability

### 3.3 Key Architectural Patterns

#### 3.3.1 Context Contribution System (src/agent/context.lisp — 1064 lines)

The most important file for Pi-Lisptc's phase 9. Implements a full contributor pipeline:

1. **Contribution class:** id, instruction (4000 char max), evidence (2000 char max), priority, lifetime (`:turn`/`:while-relevant`/`:next-request`), class (`:advice`/`:mandatory`), deduplication-key, supersedes list, conflict-group
2. **Resolution pipeline:** invoke → merge dynamic → filter consumed → deduplicate → supersede → resolve conflicts → fit budget → render
3. **Budget split:** Mandatory always included (8k char hard cap), advisory competes for ~1500 token budget
4. **Threading:** Two locks — registration lock and contributor invocation lock
5. **Diagnostics:** Full diagnostic metadata retained without payload text

#### 3.3.2 Prompt Cache Architecture (docs/context-cost-report.org)

Quantitative analysis of token waste. Key findings:
1. Volatile context inside `instructions` busts cache from token zero
2. System prompt embedding mutable session state (agenda flips) busts entire prefix
3. 46 tools at ~12.2k tokens; single tool (`web.run`) = 25% of tool budget

Solution: Stable system prompt prefix + volatile request-context suffix delivered behind conversation history.

#### 3.3.3 Revision-Gated Resources (src/resource/protocol.lisp + implementations)

Every mutable resource (workspace files, agendas, memories, papercuts) follows the same pattern:
- `resource.read` returns content + opaque revision identifier
- `resource.edit` requires the revision from the prior observation
- Stale edits are rejected with `resource-revision-stale` condition
- Post-publication verification: re-read and confirm exact match

This prevents the model from making edits based on stale observations — a critical correctness property.

#### 3.3.4 Self-Modification Safety (src/self/tools.lisp + src/state/image-commits.lisp)

Five-step protocol:
1. Journal the proposed mutation
2. Compile + install in active image
3. Check (run tests/exercises)
4. Replay-probe + commit (private snapshot with replay script)
5. Atomically select the new generation

Additional safeguards:
- Exploratory definitions tracked with undo actions
- Private commits in separate mutation-history Git repo
- Generations with complete replay scripts for full reconstruction
- Pristine recovery image as ultimate fallback

#### 3.3.5 Observer Protocol (src/agent/runtime.lisp)

Abstract `agent-observer` with 8 generic methods:
- text, reasoning, status, take-steering, steering-persisted, apply-pending-operations, authorize-command, authorize-tool

`serialized-agent-observer` wrapper ensures thread-safe callbacks during concurrent tool execution.

#### 3.3.6 Tool Lifecycle Properties (src/tools/registry.lisp)

Every tool has behavioral metadata:
- `conversation-persistence`: `:durable`/`:next-response`/`:ephemeral`
- `provider-round-trip-barrier-p`: forces model round trip
- `execution-policy`: `:concurrent`/`:exclusive`/`:serialized`
- `child-safe-p`: whether child agents can use
- `compact-result-visible-p`: whether results survive compaction

### 3.4 Memory System (src/state/memories.lisp)

- Append-only log with replacement records and recall tombstones
- Deterministic weighted lexical relevance scoring (no embeddings)
- Memory class: identifier, timestamps, scope (workspace/global), workspace, title (200 chars), content (5000 chars), tags (16 max, 80 chars each)
- Process-local recursive lock

### 3.5 RLM (docs/rlm.org)

Three-layer design:
- **Inference call:** One bounded operation
- **Inference frame:** Private ephemeral conversation with contract + budget
- **Root completion:** Content-addressed objects, dedicated Lisp environment

Budgets: calls, tokens, depth — thread-safe atomic reservation. Output tranches capped at 1/4 pool.

### 3.6 What Pi-Lisptc Should NOT Port

- SBCL live image save/restore (platform-specific, complex)
- Recovery image boot loop (requires separate binary)
- Private mutation-history Git repos (heavy infrastructure)
- `self.*` agent surgery tools (out of scope for v1)
- Native FFI search library (fff)
- S-expression configuration files (YAML/JSON more universal for TypeScript project)

### 3.7 Build System

- ASDF system definition + Qlot for dependency management
- Nix flake for reproducible builds
- Custom build scripts for active image, recovery image, static releases
- Containerfile for server deployment
- s6 service manager for production
- GitHub Actions CI with Nix

---

## 4. Cross-Repository Dependency Map

```
Pi-Lisptc (plan only)
    │
    ├── depends on → Pi (earendil-works/pi) [NOT CLONED — external]
    │                  ├── buildSystemPrompt API
    │                  ├── ExtensionAPI (CustomEditor, ExtensionAPI)
    │                  ├── session hooks (session_start, before_agent_start, etc.)
    │                  └── opencode-go-cache extension
    │
    ├── depends on → lisptc (1hachem/lisptc) [CLONED]
    │                  ├── packages/interpreter (lisp.ts, mcp.ts, source.ts)
    │                  ├── packages/repl (AgentRepl, MemoryRepl)
    │                  ├── apps/pi/extension (lisp-repl.ts, system-prompt.ts)
    │                  └── lisptc.gbnf (grammar)
    │
    ├── depends on → Vestige (samvallad33/vestige) [NOT CLONED — external]
    │                  ├── MCP tools: recall, smart_ingest
    │                  └── Hybrid keyword/semantic search, FSRS
    │
    └── inspired by → autolith (lambda-symbolics/autolith) [CLONED for analysis]
                       ├── Context contribution system (phase 9)
                       ├── Bounded RLM (phase 10)
                       ├── Agenda/papercut surfaces (phase 11)
                       └── Soft generations (phase 12)
```

## 5. Quantitative Comparison

| Metric | Pi-Lisptc | lisptc | autolith |
|--------|-----------|--------|----------|
| Lines of code | 0 | ~8,000+ | ~25,000+ |
| Test files | 0 | ~30 | 4,300+ |
| Source files | 0 | ~80 | ~80+ |
| ADRs | 9 | 0 | 0 (uses AUTOLITH.org) |
| Planning docs | 9 + 14 plans | 1 README + 1 CLAUDE.md | 7+ .org docs |
| Runtime | N/A (planned: Node.js) | Node.js >= 22.6 | SBCL (Linux/macOS/BSD) |
| Language | TypeScript + Lisp | TypeScript + Lisp | Common Lisp |
| Package manager | TBD | pnpm + Turborepo | Qlot + ASDF |
| CI/CD | None | GitHub Actions | GitHub Actions + Nix |
