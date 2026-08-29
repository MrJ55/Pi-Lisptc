# Review-by-All — Consolidated Risk Register

Risks from all five reviews, fact-checked, with mitigations drawn from the best insights.

---
## Critical Risks

| ID | Risk | Source | Probability | Impact | Mitigation | Owner |
|---|------|--------|------------|--------|------------|--------|
| R01 | **Interpreter reset on runtime error destroys mind** | GLM5p3 (verified) + Luna + Terra | Certain | Critical | Catch `EvalException` separately; preserve definitions; only reset on catastrophic corruption | Phase 2 |
| R02 | **SYSTEM_PROMPT excludes interpreter source** | GLM5p3 (verified) | Certain | Critical | Concatenate `INTERPRETER_SOURCE_LLM` explicitly in prompt assembly | Phase 1 |
| R03 | **No upstream SHAs pinned** | All 5 | Certain | High | Pin Pi, lisptc, Vestige SHAs in UPSTREAM-PINS.md before any implementation | Phase 0 |
| R04 | **Volatile mind state in system prompt busts cache** | GLM5p3 + Autolith evidence | Certain | High | Separate stable prefix (Layer 0) from volatile state (Layer 2 trailing message) | Phase 1 |
| R05 | **Unvalidated generated code reaches eval** | All 5 | Likely (current upstream behavior) | Critical | Parse-before-eval pipeline; allowlist validation; retry with feedback | Phase 2 |

## High Risks

| ID | Risk | Source | Probability | Impact | Mitigation | Owner |
|---|------|--------|------------|--------|------------|--------|
| R06 | **Vestige MCP API instability** | GLM5p3 | Likely | High | Vestige adapter with version detection, retry, fallback | Phase 4 |
| R07 | **Full interpreter source exceeds context budget** | GLM5p3 (verified sizes) | Likely | High | Create `INTERPRETER_SOURCE_LLM` excluding 842 lines of irrelevant code | Phase 1 |
| R08 | **Provider lock-in from Fireworks-hardcoded extension** | All 5 (verified) | Certain | Medium | Capability registry + `tool-call` mode + `retry` mode | Phase 3 |
| R09 | **No CI/CD enables silent regressions** | GLM5p3 + Sonnet | Certain | Medium | Set up Vitest + GitHub Actions before Phase 0 completes | Phase 0 |
| R10 | **`string-trim` bug corrupts agent data** | GLM5p3 (verified) | Possible | Medium | Report upstream with fix; patch in prelude if not fixed | Upstream |
| R11 | **Memory injection via reification** | Terra | Possible | High | 8-stage safety pipeline; data-only literals; narrow allowlist | Phase 7 |
| R12 | **No test coverage for Pi extension** | All 5 (verified: 0 tests) | Certain | Medium | 6-level test pyramid; 5 validation gates; contract tests | All |
| R13 | **Dual authority for model/provider** | Luna | Likely | Medium | Pi is sole authority; lisptc has no provider model (verified) | Phase 0 |
| R14 | **Phase 6 (persistence) blocks 3 subsystems** | Sonnet | Likely | Medium | Start schema design in Phase 3; implement minimal store in Phase 4 | Phase 3 |
| R15 | **Context contributors unbounded** | Luna + Sonnet + Terra | Likely | High | Typed contributions, budget allocation, mandatory/advisory split | Phase 9 |
| R16 | **Unbounded RLM if implemented without guards** | Luna + GLM5p3 | Possible if triggered | Critical | Host-enforced budgets; measured-need gate; nested-blocking risk | Phase 10 |

## Medium Risks

| ID | Risk | Source | Probability | Impact | Mitigation |
|---|------|--------|------------|--------|--------|
| R17 | Retry budget (2-3) insufficient for weak models | GLM5p3 | Possible | Medium | Configurable per-provider; default 3 for grammar, 5 for retry |
| R18 | OAuth port conflict on multi-instance | GLM5p3 (verified: default 8909) | Unlikely | Low | Port is overridable via env var; document this |
| R19 | `sendWhenIdle` 50ms polling race condition | GLM5p3 | Unlikely | Low | Accept as upstream limitation; document |
| R20 | Duplicate `jsonToLisp`/`jsToLisp` diverge | GLM5p3 | Possible | Low | Upstream maintenance risk; monitor |
| R21 | `packages/ai` empty, no standalone testing | GLM5p3 (corrected: 4 comment lines) | Certain | Low | Test through Pi extension only for v1 |
| R22 | ADR-0004 replace policy causes data loss | Sonnet | Possible | Medium | Consider undo/redo for pinned items; define retention policy |
| R23 | Validation latency blocks REPL | Sonnet | Possible | Medium | Layered validation: fast syntax check, slow effect check |
| R24 | Vestige reification OOM on large datasets | Sonnet | Possible | Medium | Chunked queries; token budget cap; streaming serialization |
| R25 | Snapshots version-fragile | Sonnet + Luna | Possible | Medium | Schema versioning; compatibility metadata; migration tests |
| R26 | License not set for Pi-Lisptc | GLM5p3 | Certain | Low | Set license before public release |

## Low Risks

| ID | Risk | Source | Probability | Impact |
|---|------|--------|------------|--------|
| R27 | Session server has no authentication | GLM5p3 (verified) | Unlikely | Low (not used by Pi-Lisptc) |
| R28 | Naive MCP tool search (substring only) | GLM5p3 | Certain | Low (adequate for v1) |
| R29 | No `finally` in some try/catch (corrected: exists) | GLM5p3 (self-corrected) | N/A | N/A (claim was wrong) |
| R30 | Autolith phases triggered without evidence | GLM5p3 + Luna | Possible | Medium | Quantitative exit criteria; daily-stable requirement |

## Release Blockers (from Luna — All Must Pass Before Production)

1. No capability bypass (generated Lisp cannot execute without validation)
2. No unbounded recursion (RLM budgets enforced)
3. No uncontrolled external side effects (MCP calls are audited)
4. Deterministic state behavior after failures (definitions survive `EvalException`)
5. No multiple competing authorities (Pi is sole model/provider authority)