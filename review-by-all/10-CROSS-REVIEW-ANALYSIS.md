# Review-by-All — Cross-Review Analysis

Where the five reviews agree, complement each other, diverge, and err.

---

## 1. Agreement Matrix

### 1.1 Perfect Agreement (All 5 Reviews)

| Topic | Agreement | Evidence Strength |
|-------|----------|------------------|
| Merge-not-replace system prompt (ADR-0001) | 100% | Code-verified: `lisp-repl.ts` L322 returns only lisptc POLICY |
| Validate before eval (ADR-0003) | 100% | All identify this as the #1 safety requirement |
| Cabinet (Vestige) vs cortex (REPL) separation | 100% | Conceptual agreement, well-defined in ADR-0002 |
| Replace-not-accumulate (ADR-0004) | 100% | Prevents the most common agent memory failure mode |
| Two profiles (ADR-0006) | 100% | Prevents mode confusion |
| Autolith as pattern source, not platform | 100% | All explicitly reject SBCL/image/self-mutation |
| No upstream SHAs pinned | 100% | Verified: all entries in UPSTREAM-PINS.md are TBD |
| Zero runnable code exists | 100% | Verified: entire Pi-Lisptc repo is planning docs |

### 1.2 Strong Agreement (4/5 Reviews)

| Topic | Dissenting Review | Nature of Dissent |
|-------|----------------|-------------------|
| `repl.reset()` on error destroys mind | Gemini (didn't explicitly call this out) | Gemini focused on validation gates, not error recovery behavior |
| Need `IProvider` interface | GLM5p3 (focused on `tool-call` mode instead) | GLM5p3 proposed a concrete mode rather than an abstract interface |
| Persistence schema needed | Gemini (didn't call this out) | Gemini's roadmap mentions persistence but not schema concerns |
| Exit criteria per phase | Gemini (has exit criteria but less formal) | Gemini has SLOs but not structured exit gates per phase |
| Test strategy missing | Gemini (has test strategy, just less comprehensive) | Gemini's 5-gate approach is narrower than Terra's 6-level pyramid |

### 1.3 Meaningful Disagreements

| Topic | Position A | Position B | Resolution |
|-------|-----------|-----------|----------|
| **Phase ordering** | Sonnet: reorder Phase 03 before 04, Phase 06 before 05 | GLM5p3: insert Phase -1, merge cache into Phase 1 | **Synthesis**: Both have merit. Sonnet's critical-path analysis (00→01→03→04→06→07) is correct. GLM5p3's cache architecture must be in Phase 1. Merge: -1→0→1(+cache)→2(+error-recovery)→3(+tool-call)→4→5→6→7. |
| **Effort estimate** | Gemini: 18-24 days | GLM5p3: 36 days (core), 54 (full) | **Gemini is more optimistic.** The gap is explained by scope: Gemini estimates the happy path only. GLM5p3 includes pre-work, upstream fixes, CI, and testing overhead. A realistic estimate is 30-40 days for a single experienced developer. |
| **`string-trim` bug** | Only GLM5p3 identified this | 4 other reviews missed it | **GLM5p3 is correct.** Verified: `(string-trim "\thello\t")` silently fails. This should be reported upstream. |
| **IRRELEVANT interpreter source** | Only GLM5p3 quantified this (842 lines) | Other reviews didn't analyze source.ts file list | **GLM5p3 is correct.** `mcp-broker.ts` (365 lines) and `mcp-oauth.ts` (200 lines) are invisible to the LLM. |
| **`tool-call` provider mode** | Only GLM5p3 proposed this | Others rely on grammar or retry only | **GLM5p3 is correct.** For OpenAI/Anthropic, forced single-tool calling is more reliable than free-text retry. This is the dominant constrained-output approach in production AI systems. |

---

## 2. Complementary Insights (No Overlap)

### 2.1 Each Review's Unique Contribution

| Review | Unique Insight Not In Any Other | Value |
|--------|-------------------------------|-------|
| **Luna** | Seven distinct state classes (transcript, working mind, turn evidence, durable memories, preferences, agenda/papercuts, inference traces) | Prevents conflation of different state types. No other review provides this taxonomy. |
| **Luna** | Authority table (who owns what) | Prevents dual-authority anti-pattern. Concrete: "model/provider authority belongs to Pi, not lisptc." |
| **Luna** | "Interpreter reset as transactional rollback is categorically rejected" | Explicit anti-pattern. Other reviews say "don't reset" but don't name the pattern to reject. |
| **Luna** | Release blockers (5 conditions for production) | No other review defines production readiness criteria. |
| **Sonnet** | Phase-06 is THE bottleneck (blocks mind, vestige, AND Autolith) | Specific dependency analysis not in other reviews. Actionable: "start schema design in phase-03." |
| **Sonnet** | Quantitative SLOs (2s compile, 500MB memory, 100ms/1000 items) | Only review with concrete performance targets. |
| **Sonnet** | Autolith feasibility matrix (High/Medium/Medium-High per feature) | Grounded assessment of what can actually be ported to TypeScript. |
| **Sonnet** | ADR-0004 data-loss risk (need undo/redo) | Other reviews accept replace-not-accumulate without considering data loss. |
| **Terra** | 8-stage memory safety pipeline for reification | Most detailed security analysis. Names `repl.eval(record.text)` as explicit anti-pattern. |
| **Terra** | `CANCELLED` as distinct capability result code | First-class cancellation, not an error. Other reviews don't distinguish. |
| **Terra** | `reserveTokens` in context budgets | Ensures critical system context always has room. |
| **Terra** | Differential testing (Pi enabled vs disabled) | Novel test methodology for detecting regression from the extension. |
| **Terra** | `redactedAt` timestamp on events | Redaction itself is an auditable event. |
| **Terra** | Profile type with `persistencePolicy` (`off|ephemeral|durable`) | Formal profile schema beyond just "two profiles." |
| **Terra** | 8 new ADRs (0010-0017) | Most comprehensive ADR expansion. |
| **Gemini** | Concrete file placement (`profiles.ts`, `vestige.ts`, `audit.ts`, etc.) | Most practical guidance for where to put code. |
| **Gemini** | `opencode-go-cache` as only approved outer tool | Named specifically, actionable. |
| **Gemini** | Five validation gates with test code | Most actionable testing guidance. |
| **Gemini** | Asymmetric test coverage (95% provider-policy, 90% lisp-repl, etc.) | Risk-based test investment. |
| **Gemini** | Reification data schema (`:turn-id`, `:kind`, `:confidence`, `:tags`) | Concrete Lisp data structure for memory items. |
| **Gemini** | Action API (`mind.recall-all`, `mind.recall-by-tag`, etc.) | Concrete function signatures for memory access. |
| **GLM5p3** | `string-trim` bug in upstream | Only code-level bug found. Would cause silent data corruption. |
| **GLM5p3** | SYSTEM_PROMPT/INTERPRETER_SOURCE disconnect | Most impactful finding — the LLM would have zero knowledge of the language. |
| **GLM5p3** | Token economics (~180k saved per 10-turn session from cache) | Quantified cost impact. |
| **GLM5p3** | `tool-call` provider mode | Most reliable constrained-output approach for OpenAI/Anthropic. |
| **GLM5p3** | Fact-checking other reviews (10 refutations) | Meta-contribution: quality control on all other reviews. |

### 2.2 Insights That Should Be Combined

**Memory safety pipeline**: Terra's 8-stage pipeline + Gemini's reification data schema + GLM5p3's quality threshold. Together these form a complete memory safety system: retrieve → validate → rank → serialize → parse → allowlist → eval → quality-check.

**Context system**: Autolith's contribution class (1064 lines) + Luna's provenance/cost metadata + Sonnet's 1500 token budget + Terra's 8-step algorithm + Terra's `reserveTokens` = the most complete context system specification.

**Testing**: Terra's 6-level pyramid + Gemini's 5 validation gates + GLM5p3's contract tests + Sonnet's SLOs + Luna's differential testing = comprehensive test strategy.

---

## 3. Where Reviews Err

### 3.1 Gemini: Fabricated Interfaces

Gemini's `INTERFACES-AND-INVARIANTS.md` describes `LispSession`, `MCPBroker`, and `SecretsStore` classes with methods that don't exist. The actual code uses `AgentRepl`, standalone functions in `mcp-broker.ts`, and a `SecretsStore` interface with a different `get` return type. If implemented as described, the code would fail immediately.

**Correction adopted:** Use actual class names (`AgentRepl`, `MemoryRepl`) and actual method signatures from source code.

### 3.2 Sonnet: Wrong Repo Attribution

Sonnet claims `src/prelude/mind-api.lisp` is 570 bytes. The file exists in Pi-Lisptc (the plan repo), not in lisptc upstream. This is a scope confusion — Sonnet appears to have been checking the planning repo for a file that belongs to the implementation.

**Correction adopted:** The file is in Pi-Lisptc. It's all commented-out stubs. The actual upstream prelude is embedded in `lisp.ts` as a template literal.

### 3.3 GLM5p3: Three False Claims

1. **"No `finally` clause"**: Four instances exist. Correction: finally is available but uncommon.
2. **"`packages/ai/src/index.ts` is completely empty"**: Contains 4 lines of design comments. Correction: not empty, but has no executable code.
3. **"OAuth port is fixed"**: Overridable via env var. Correction: default is fixed but configurable.

### 3.4 All Reviews: Wrong Self-Modification Protocol Name

Three reviews (GLM5p3, Luna, Gemini) describe Autolith's self-modification as a "5-step protocol: journal → compile → check → replay-probe → select." The actual code in `image-commits.lisp` has 6 stages: `:manifest`, `:history`, `:selection`, `:validation`, `:replay-probe`, `:publish`. There is no "compile" stage (Lisp compiles at load time). The "select" stage is `:selection` (pointer resolution). AGENTS.md uses simplified names as a summary.

**Correction adopted:** The actual stage names from the source code should be used if Pi-Lisptc ever needs this pattern.

---

## 4. Review Quality Assessment

| Review | Code Grounding | Factual Accuracy | Architectural Depth | Practical Actionability | Unique Value |
|--------|---------------|-------------------|---------------------|----------------------|-------------|
| **Luna** | Medium (read lisptc structure, not line-level) | High (no refutations) | **Highest** (authority table, state classes, release blockers) | High (44-item checklist) | Boundary enforcement, authority model |
| **Sonnet** | Low (no line-level code reading) | Medium (1 misattribution) | Medium (gap analysis, feasibility) | **Highest** (SLOs, timeline, critical path) | Performance targets, bottleneck identification |
| **Terra** | Medium (read lisptc structure, referenced Autolith specifics) | High (no refutations) | **Highest** (formal types, 8-step algorithm, security) | High (concrete TypeScript types) | Security, memory safety, formal interfaces |
| **Gemini** | Medium (read file sizes, but fabricated interfaces) | Low (5 refutations including fabricated classes) | Medium (correct high-level assessment) | **Highest** (file placement, test code, action API) | Practical execution, test gates |
| **GLM5p3** | **Highest** (line-by-line source reading) | High (3 minor errors, 0 major) | High (prompt cache, token economics) | High (effort estimates, critical path) | Upstream bugs, token economics, fact-checking |

### Best Review Per Dimension

- **Deepest architecture**: Luna (authority table, state classes) + Terra (formal types, security)
- **Most practical**: Gemini (file placement, test code) + Sonnet (SLOs, timeline)
- **Most accurate**: GLM5p3 (line-by-line reading, upstream bugs)
- **Best test strategy**: Terra (6-level pyramid) + Gemini (5 validation gates)
- **Best roadmap**: Sonnet (critical path, bottleneck) + GLM5p3 (effort estimates)