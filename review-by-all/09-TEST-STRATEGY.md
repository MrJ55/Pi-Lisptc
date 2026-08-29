# Review-by-All — Test Strategy

Unified from Terra (6-level pyramid), Gemini (5 validation gates), GLM5p3 (contract tests), and Sonnet (SLOs).

---
## 1. Test Framework

**Vitest** — consistent with lisptc's existing test infrastructure.

## 2. Test Pyramid (6 Levels, from Terra)

| Level | Focus | Example | Source |
|---|---|---|---|
| **Unit** | Pure schema/order/policy/budget logic | Invalid profile; stable sort; expired memory; denied grant | Terra |
| **Contract** | Prelude-host-adapter boundary | Lisp request → typed result; normalized provider result | Terra |
| **Integration** | Full controlled turn | profile → manifest → provider fixture → tool fixture → ledger | Terra |
| **Differential** | Fork vs pinned lisptc | Unchanged upstream suites; Pi enabled/disabled semantic comparison | Terra |
| **Adversarial** | Untrusted/recursive/failing inputs | Secret contributor; denied MCP; interrupted materialization; nested RLM | Terra |
| **E2E** | User observable behavior | Inspect context; cancel; no-side-effect trace replay | All |

## 3. Validation Gates (from Gemini, Concrete Test Code)

**Gate 1: Image Safety (Phase 2)**
- Eval `(defun test () (+ 1 2` (missing paren) → parse-error, retry ≤ 3
- Session still usable after: `(+ 1 2)` → 3
- Exit: No REPL corruption in 100+ turns

**Gate 2: Reification Safety (Phase 7)**
- Reification form matches `\(mind.replace-turn-recall\s+'\(`
- Must NOT contain `eval(` or raw record.text
- Exit: No arbitrary code execution from Vestige recall in 100+ turns

**Gate 3: Provider Modes (Phase 3)**
- Fireworks → grammar mode active
- OpenAI → tool-call mode active (`eval_lisp_form` tool, forced tool_choice)
- Fallback → retry mode active
- Exit: No silent fallback failures

**Gate 4: Replace-Not-Accumulate (Phase 7)**
- Turn 1: 3 recall items → Turn 2: 2 different items
- Turn 2 must have exactly 2 items (not 5)
- Turn 1 IDs must NOT be present
- Exit: No memory bloat

**Gate 5: Smart Ingest Gating (Phase 7)**
- Duplicate fact → `skip` with reason matching `/duplicate/`
- Novel high-confidence (0.95) fact → `ingest`
- Exit: No noise in durable memory

## 4. Contract Tests (from GLM5p3)

Verify Pi's actual API behavior:
- `buildSystemPrompt({ customPrompt })` still appends project context
- `setActiveTools([])` clears all tools
- `before_provider_request` modifications are composable with other extensions
- `AgentRepl.eval(code)` returns string output
- `AgentRepl.reset()` clears all definitions
- `AgentRepl.takeHalted()` returns true after `(halt)`

## 5. Coverage Targets (from Gemini, Risk-Based)

| Component | Target | Rationale |
|---|---|---|
| provider-policy.ts | 95% | Most critical for no-silent-failure |
| lisp-repl.ts | 90% | Core of forced action channel |
| action-channel.ts | 90% | Minimal allowlist enforcement |
| vestige.ts | 85% | Reification safety |
| system-prompt.ts | 80% | Prompt assembly correctness |
| context-assembly.ts | 80% | Budget enforcement |
| profiles.ts | 75% | Profile switching |

## 6. SLOs (from Sonnet)

| Metric | Target | Measurement Point |
|---|---|---|
| Compile latency | < 2s | Phase 4 MCP bootstrap |
| Memory usage | < 500MB for 10k LOC | Phase 8 harden |
| Vestige reification | < 100ms for 1000 items | Phase 7 |
| Prompt cache hit rate | > 80% on turns 3+ | Phase 1+ |
| Retry rate | < 5% on grammar providers | Phase 3 |
| Recall latency | p99 < 200ms | Phase 7 |
| Zero crash sessions | 50+ turn sessions | Phase 7 |

## 7. Differential Tests (from Terra)

Run identical test scenarios with Pi enabled and disabled. Compare semantic behavior:
- Same prompt → same prompt structure
- Same error → same error format
- Provider switch → only adapter/config changes
- Profile switch → prompt/tools change as expected

## 8. Adversarial Tests (from Terra)

- Secret/oversized contributor tries to inject credentials into context
- Denied MCP server attempts connection → denied before adapter
- Interrupted materialization → no partial active artifact
- Nested RLM → depth/time/cost limits enforced
- Cancellation during tool call → one coherent terminal result
- Corrupted Vestige response → filtered by quality threshold
- Model outputs prose mixed with Lisp → parse rejection, retry

## 9. CI Requirements

**Per PR:**
- Formatting + types + lint + unit tests
- Upstream lisptc compatibility (unchanged test suite)
- Changed-boundary contract tests
- Secret scan (no API keys in committed code)
- Persisted-schema migration tests

**Release Candidate:**
- All validation gates pass
- Provider/MCP/store fixtures pass
- Adversarial policy/redaction/budget tests pass
- Migration/rollback rehearsal
- No-side-effect replay test
- Manual review of new capabilities/grants

## 10. Required Fixtures

- Same inputs/profile/contributors → same manifest + digest
- Order survives different contributor execution order
- Over-budget candidates record deterministic omission reasons
- Sensitivity policy acts before render
- Contributor failure cannot remove required system context
- Expired/superseded materializations excluded
- Diagnostics redact secrets