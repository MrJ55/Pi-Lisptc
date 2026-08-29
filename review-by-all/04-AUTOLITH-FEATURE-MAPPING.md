# Review-by-All — Autolith Feature Mapping

Validated against actual Autolith source code (42+ files read).

---

## Verified Autolith Facts Used by All Reviews

| Claim | Source File | Verified |
|--------|-----------|----------|
| Advisory budget = 1500 tokens | `src/agent/context.lisp` L23 | ✅ |
| Mandatory total cap = 8000 chars | `src/agent/context.lisp` (budget fitting) | ✅ |
| Revision-gated resources | `src/resource/protocol.lisp` | ✅ |
| Tool lifecycle: persistence, barrier, execution-policy, child-safe, compact-visible | `src/tools/registry.lisp` L466-527 | ✅ |
| Context cost: volatile context in system prompt is top waste | `docs/context-cost-report.org` findings #1, #3 | ✅ |
| Self-modification has 6 stages (not 5 as commonly claimed) | `src/state/image-commits.lisp` | ✅ |
| Memory uses lexical ranking, no embeddings | `src/state/memories.lisp` | ✅ |
| Generations have complete replay scripts | `src/state/generations.lisp` | ✅ |
| RLM uses depth/tokens/call budgets, thread-safe atomic reservation | `docs/rlm.org` | ✅ |
| Contribution class has: id, instruction (4k), evidence (2k), priority, lifetime, class | `src/agent/context.lisp` | ✅ |
| Skills: content-addressed (SHA-256), catalog-based, max 32/turn, 128KB total | `src/skills/runtime.lisp` | ✅ |
| Observer protocol: abstract agent-observer with 8 generic methods | `src/agent/runtime.lisp` | ✅ |

## Feature Mapping (Validated)

| Autolith Feature | Pi-Lisptc Phase | Feasibility | Key Adaptation | Risk |
|---|---|---|---|---|
| Context contributors | 9 | High | TypeScript host-side registry | None |
| Memory recall contributor | 7→9 | High | Stop-word filtering, top-6, 1900 chars | None |
| Prompt cache separation | **New** | High | Stable prefix + volatile suffix | Must verify Pi supports trailing messages |
| Tool lifecycle properties | 4/8 | Medium | Lisp metadata on MCP tools | lisptc has no tool registry |
| Revision-gated resources | 9 | Medium | For file-backed resources only | In-memory state has natural serialization |
| Agenda surface | 11 | High | Alist + Vestige tags | None |
| Papercut surface | 11 | High | Alist + Vestige tags | None |
| Soft generations | 12 | High | Prelude serialization to .sexp | Restore may fail if MCP not loaded |
| Skill loading | 12 | Medium | Directory scanning + eval | Ordering of MCP-dependent skills |
| Bounded RLM | 10 | **Low** | Must bypass interpreter's blocking jobs runtime | Nested-blocking architectural conflict |
| Self-modification safety | **Out of scope** | N/A | Not ported | N/A |
| Recovery images | **Out of scope** | N/A | Not ported (SBCL-only) | N/A |
| Private mutation repos | **Out of scope** | N/A | Not ported | N/A |

## RLM Blocking Issue (GLM5p3, verified)

lisptc's `Atomics.wait` (in `jobs.ts` L145) blocks the main thread during MCP calls. RLM sub-requests would need to:
1. Make HTTP requests to the provider (async)
2. Wait for the response
3. Eval the response in the interpreter

But step 1 requires the event loop, which is blocked by the parent `Atomics.wait`. **Resolution:** RLM must bypass the interpreter's jobs runtime. The host (TypeScript) makes provider requests directly, then feeds responses to the interpreter.

## Pattern: Content-Addressed Skills (from Autolith, adapted)

Autolith uses SHA-256 content addressing for skills. Pi-Lisptc should:
1. Scan `.lisptc/skills/` for `.lisp` files
2. Content-address cache by file hash
3. Model selects from catalog (name + description)
4. `mind/load-skill!` reads and evals the file
5. `:provider-round-trip-barrier-p` ensures skills load before dependent tools

## Pattern: Observer Protocol (from Autolith, adapted)

Autolith uses `agent-observer` with 8 methods. Pi-Lisptc should implement a simplified version:
- `onText(text)` — model output
- `onReasoning(text)` — thinking content
- `onStatus(status)` — progress indication
- `onToolResult(tool, args, result)` — MCP result
- `onError(error)` — structured error
- `onSteering(input)` — user interruption

## What NOT to Port (Unanimous)

- SBCL live-image save/restore
- Recovery image boot loops
- Private mutation-history Git repos
- `self.*` agent surgery tools
- Native FFI search (fff)
- S-expression configuration files
- CLOS protocol dispatch (use TypeScript interfaces)
- Full Autolith orchestration model