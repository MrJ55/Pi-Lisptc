# Review-by-GLM5p3 — Risk Register

Consolidated risks from all three repos, with severity, probability, and mitigations.

---

## Risk Summary

| ID | Risk | Severity | Probability | Phase | Mitigation Status |
|----|------|----------|-------------|-------|------------------|
| R01 | Interpreter error recovery resets mind | Critical | Certain | 2 | **Unmitigated** — upstream behavior must be patched |
| R02 | System prompt excludes interpreter source | Critical | Certain | 1 | **Unmitigated** — Pi-Lisptc must concatenate explicitly |
| R03 | No upstream SHAs pinned | Critical | Certain | 0 | **Unmitigated** — blocks all implementation |
| R04 | Vestige MCP API instability | High | Likely | 4/7 | **Partially mitigated** — adapter layer proposed |
| R05 | Prompt cache busting from volatile mind state | High | Certain | 1/7 | **Unmitigated** — architecture change required |
| R06 | Full interpreter source exceeds context budget | High | Likely | 1 | **Partially mitigated** — source subset proposed |
| R07 | Provider lock-in from Fireworks-hardcoded extension | Medium | Likely | 3 | **Partially mitigated** — capability registry planned |
| R08 | Retry budget insufficient for weak models | Medium | Possible | 2 | **Unmitigated** — no per-provider tuning |
| R09 | RLM blocked by synchronous interpreter | Medium | Deferrable | 10 | **Accepted** — deferred with measured-need gate |
| R10 | string-trim bug corrupts agent data | Medium | Possible | Upstream | **Unmitigated** — upstream bug, no fix committed |
| R11 | No CI/CD enables silent regressions | Medium | Certain | 0 | **Unmitigated** |
| R12 | Autolith phases triggered without evidence | Low | Possible | 9-12 | **Partially mitigated** — entry criteria proposed |
| R13 | OAuth port conflict on multi-instance | Low | Unlikely | Upstream | **Unmitigated** — upstream issue |
| R14 | Session server lacks authentication | Low | Unlikely | Upstream | **Accepted** — not used by Pi-Lisptc |
| R15 | No test coverage for Pi extension | Medium | Certain | All | **Unmitigated** |
| R16 | `sendWhenIdle` polling race condition | Low | Unlikely | Upstream | **Accepted** — upstream issue |
| R17 | Multi-extension composition on Pi hooks | Medium | Unknown | 0 | **Unmitigated** — must test |
| R18 | Phase 8 sandbox not implemented, mind vulnerable | Medium | Likely | 8 | **Partially mitigated** — promoted to recommended |
| R19 | Mind survives process restart untested | Medium | Possible | 6 | **Unmitigated** — must verify |
| R20 | Recall quality below threshold, noise injected | Medium | Possible | 7 | **Unmitigated** — quality threshold proposed but not specified |
| R21 | Duplicate jsonToLisp implementations diverge | Low | Possible | Upstream | **Accepted** — upstream maintenance risk |
| R22 | `packages/ai` empty, no standalone testing | Low | Certain | Upstream | **Accepted** — upstream gap |
| R23 | License not set | Low | Certain | Repo | **Unmitigated** — legal risk |

---

## Detailed Risk Entries

### R01: Interpreter Error Recovery Resets Mind
**Phase:** 2
**Severity:** Critical — directly contradicts G3 (Living Mind)
**Probability:** Certain — this is the current upstream behavior

**Description:** lisptc's `lisp-repl.ts` catches all exceptions from `evalCode` and calls `repl.reset()`, destroying all definitions. A single MCP timeout, division by zero, or type error lobotomizes the agent.

**Concrete Scenario:**
1. Agent defines `(defun analyze-module (path) ...)` — working
2. Agent calls it — MCP server times out → EvalException
3. `repl.reset()` called — `analyze-module` no longer exists
4. Agent has lost its mind mid-session

**Mitigation:**
1. Wrap `evalCode` to catch `EvalException` separately from catastrophic errors
2. On `EvalException`: report error to model, preserve definitions, do NOT reset
3. Only reset on detected interpreter corruption (nil in internals)
4. Write a test: define function → trigger error → verify function still exists

**Effort:** ~0.5 day

---

### R02: System Prompt Excludes Interpreter Source
**Phase:** 1
**Severity:** Critical — LLM has no knowledge of the language it must output
**Probability:** Certain — verified in `system-prompt.ts` source

**Description:** `SYSTEM_PROMPT` in `system-prompt.ts` imports `INTERPRETER_SOURCE` but the exported constant is only `POLICY`. The interpreter source is NOT included in the prompt the LLM receives.

**Mitigation:**
1. In Pi-Lisptc's prompt assembly, explicitly concatenate `INTERPRETER_SOURCE_LLM` (or full `INTERPRETER_SOURCE`)
2. Verify by logging the assembled prompt and searching for `defun` definitions
3. Upstream fix: submit PR to lisptc including source in `SYSTEM_PROMPT`

**Effort:** ~0.5 day (Pi-Lisptc side)

---

### R03: No Upstream SHAs Pinned
**Phase:** 0
**Severity:** Critical — implementation cannot begin responsibly
**Probability:** Certain — all entries are TBD

**Description:** `UPSTREAM-PINS.md` has no commit hashes. Pi, lisptc, and Vestige are active projects. Any code written against current APIs may break.

**Mitigation:**
1. Record exact SHAs for Pi, lisptc, Vestige
2. Document the specific APIs used from each
3. Set up Dependabot or similar for upstream tracking
4. Define compatibility test suite that runs against pinned versions

**Effort:** ~0.5 day

---

### R04: Vestige MCP API Instability
**Phase:** 4/7
**Severity:** High — blocks Phase 7
**Probability:** Likely — UPSTREAM-PINS.md explicitly warns about this

**Description:** Vestige's tool names "may vary by version." Pi-Lisptc's recall and ingest implementations depend on specific tool names and schemas.

**Mitigation:**
1. Define `VestigeAdapter` interface in Phase 4
2. Implement version detection (call `list-tools`, match against known schemas)
3. If tool names change, map old → new
4. Pin Vestige SHA and test recall/ingest against it

**Effort:** ~2 days for adapter + version detection

---

### R05: Prompt Cache Busting from Volatile Mind State
**Phase:** 1/7
**Severity:** High — multiplies token costs 5-10x
**Probability:** Certain — by design in current plan

**Description:** The merged prompt includes `mind_active` (which changes every turn) directly in the system prompt. This invalidates the entire prompt cache prefix on every user message.

**Quantitative Impact:**
- System prompt: ~20k tokens
- Per-turn without cache: 20k (system) + 2k (mind) + conversation = 22k+
- Per-turn with cache: 2k (mind) + conversation = 2k+
- Savings over 10-turn session: ~180k tokens
- Cost savings at $3/M input tokens: ~$0.54 per session

**Mitigation:**
1. Split prompt into stable (Layer 0) and volatile (Layer 2) regions
2. Inject Layer 2 as trailing developer message
3. Verify cache hit rates with provider telemetry

**Effort:** ~2 days (depends on Pi's message API)

---

### R06: Full Interpreter Source Exceeds Context Budget
**Phase:** 1
**Severity:** High — may make the project non-viable on smaller context windows
**Probability:** Likely — 11 source files, ~4866+ lines

**Mitigation:**
1. Create `INTERPRETER_SOURCE_LLM` excluding irrelevant files
2. Measure exact token count for the optimized subset
3. If still too large, split into L0 (core semantics) and L1 (full reference, loaded on demand)

**Effort:** ~1 day

---

### R07: Provider Lock-in
**Phase:** 3
**Severity:** Medium — limits G6 (any major provider)
**Probability:** Likely — extension is hardcoded for Fireworks

**Mitigation:**
1. Implement capability registry with provider detection
2. Add `tool-call` mode for OpenAI/Anthropic
3. Add `retry` mode as universal fallback

**Effort:** ~3 days

---

### R08: Retry Budget Insufficient
**Phase:** 2
**Severity:** Medium — causes unnecessary session failures
**Probability:** Possible — depends on model quality

**Mitigation:**
1. Make retry budget configurable per provider
2. Default: 3 for grammar mode, 5 for retry mode
3. Log retry rates and adjust based on data

**Effort:** ~0.5 day

---

### R10: string-trim Bug
**Phase:** Upstream
**Severity:** Medium — silent data corruption
**Probability:** Possible — affects tab-containing strings

**Description:** `string-trim` in lisptc's prelude checks for literal two-character strings `"\\t"`, `"\\n"`, `"\\r"` instead of actual whitespace characters.

**Mitigation:**
1. Report upstream with fix
2. Patch in Pi-Lisptc's prelude if not fixed upstream

**Effort:** ~0.5 day

---

### R15: No Test Coverage for Pi Extension
**Phase:** All
**Severity:** Medium — regressions undetected
**Probability:** Certain — zero tests exist

**Mitigation:**
1. Add Vitest (consistent with lisptc)
2. Test prompt assembly (Phase 1)
3. Test validation pipeline (Phase 2)
4. Test recall quality threshold (Phase 7)
5. Test contributor resolution (Phase 9)

**Effort:** Ongoing, ~10% of implementation time

---

### R17: Multi-Extension Composition
**Phase:** 0
**Severity:** Medium — may prevent opencode-go-cache coexistence
**Probability:** Unknown — depends on Pi's extension API

**Mitigation:**
1. Test with both extensions loaded in Phase 0
2. If Pi doesn't support composition, implement a mediator extension

**Effort:** ~1 day (or ~3 days if mediator needed)

---

## Risk Heat Map

```
         Certain  Likely  Possible  Unlikely
Critical   R01,R02  R03     -         -
High      R05      R04,R06  -         -
Medium    R11,R15  R07,R18  R08,R10,R17,R19,R20  -
Low       R22,R23  -        R12,R13   R14,R16,R21
```
