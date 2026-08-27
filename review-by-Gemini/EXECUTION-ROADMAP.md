# Execution Roadmap (Gemini)

## Phase 0: Baseline & profiles (exit criteria: daily use)

**Goal:** `pi-default` vs `lisp-mind` launch paths.

**Tasks:**
- [ ] Extend `apps/pi/extension/system-prompt.ts` to support profile selection (`pi-default` | `lisp-mind`)
- [ ] Add `apps/pi/extension/profiles.ts` with policy selection
- [ ] Scripts/aliases for launch: `pi --profile=lisp-mind`, `pi --profile=pi-default`
- [ ] Document both profiles in README

**Exit criteria:**
- Can launch Pi in both profiles daily
- `pi-default` behaves like stock Pi
- `lisp-mind` has placeholder prompt (not yet merged)

---

## Phase 1: Prompt assembly (exit criteria: merged prompt works)

**Goal:** `buildSystemPrompt` merge + full interpreter source (optimize later).

**Tasks:**
- [ ] Rewrite `system-prompt.ts` to compose asymmetric prompt:
  ```
  Pi invariant system prompt
  + Pi coding role and safety/runtime instructions
  + AGENTS.md instructions
  + cwd, repository, files, diagnostics, path conventions
  + current task
  + lisp-mind action contract
  + bounded retrieved Vestige context or recall manifest
  ```
- [ ] Attach full interpreter source (optimize later for non-Fireworks providers)
- [ ] Always attach project context and cwd (ADR 0001)

**Exit criteria:**
- `lisp-mind` prompt merges Pi DNA + lisptc channel
- Model can generate valid Lisp actions
- No regression in `pi-default` coding ability

---

## Phase 2: Image safety (exit criteria: no REPL corruption)

**Goal:** Validate-before-eval; retry; no trash.

**Tasks:**
- [ ] Implement pre-eval pipeline in `lisp-repl.ts`:
  ```
  raw model output
    -> strip markdown fences
    -> parse to Lisp AST (lisp.ts)
    -> optional GBNF check (grammar.ts)
    -> validate allowlist (only trusted forms)
    -> eval in session
  ```
- [ ] Retry budget 2–3 on parse failure
- [ ] Log failures for diagnostics

**Exit criteria:**
- No REPL corruption from malformed eval in 100+ turns
- Retry works on weak models
- Image integrity preferred over speed

---

## Phase 3: Provider widening (exit criteria: multi-provider works)

**Goal:** grammar / tool / retry modes + cache coexistence.

**Tasks:**
- [ ] Capability registry (simple table):
  ```ts
  type ProviderMode = 'grammar' | 'strict-tool' | 'validate-retry';
  const capabilityTable: Record<string, ProviderMode> = { ... };
  ```
- [ ] Compose with cache extension (`opencode-go-cache`)
- [ ] Always host-validate before eval regardless of mode

**Exit criteria:**
- Works with Fireworks (grammar), OpenAI/Anthropic (validate-retry)
- Cache extension composes without conflict
- No silent fallback failures

---

## Phase 4: MCP bootstrap (exit criteria: MCP-in-image works)

**Goal:** Vestige + fs (etc.) in-image; thin outer tools.

**Tasks:**
- [ ] Connect Vestige MCP server to `packages/interpreter/src/mcp.ts`
- [ ] OAuth/secrets flow (`mcp-oauth.ts`, `secrets.ts`)
- [ ] Minimal outer tools allowlist in `lisp-mind` profile

**Exit criteria:**
- MCP calls work from Lisp actions
- Vestige recall works (not yet reified)
- No regression in `pi-default` tools

---

## Phase 5: User channel (exit criteria: readable UX)

**Goal:** `(reply)`/`(halt)` + pretty-print.

**Tasks:**
- [ ] Implement `(reply ...)` and `(halt ...)` in prelude
- [ ] Host pretty-printer in Pi extension
- [ ] UX prefs (e.g., compact vs verbose)

**Exit criteria:**
- Model output is readable and structured
- Host respects UX prefs
- No UX regression vs stock Pi

---

## Phase 6: Persistence (exit criteria: session continuity)

**Goal:** Prelude load/save; pins; session continuity.

**Tasks:**
- [ ] Prelude load/save on session start/end
- [ ] Pins with hard cap
- [ ] Session continuity across restarts

**Exit criteria:**
- Session state persists across restarts
- Pins work within cap
- No state leakage between profiles

---

## Phase 7: Vestige reify loop (exit criteria: living mind works)

**Goal:** Auto-recall → reify → act → ingest.

**Tasks:**
- [ ] Host auto-recall from Vestige (top-k, ranking, budget)
- [ ] Reify into persistent REPL (`mind.replace-turn-recall`)
- [ ] `smart_ingest` gating (dedup, scope, confidence threshold)
- [ ] Audit manifest (turn/effect/reification ledger)

**Exit criteria:**
- Living mind works daily (reify per turn)
- Durable facts in Vestige; skills in REPL
- No memory bloat (replace-not-accumulate)

---

## Phase 8: Optional harden (exit criteria: sandbox works)

**Goal:** Sandbox, L0/L1 prompt, workers, RLM later.

**Tasks:**
- [ ] Optional sandbox eval (phase 8)
- [ ] L0/L1 prompt separation (optional)
- [ ] Workers for async MCP calls (optional)
- [ ] RLM (phase 10 only if needed)

**Exit criteria:**
- Sandbox eval works for high-risk tasks
- Optional features do not block core path
- Document which subsets shipped

---

## Phases 9–12: Autolith additive track (optional)

**Goal:** Context contributors, bounded RLM, agendas/papercuts, soft generations.

**Tasks:**
- [ ] Phase 9: Host-side contributor registry (ADR 0007)
- [ ] Phase 10: Bounded RLM as optional Lisp operations (ADR 0008)
- [ ] Phase 11: Agendas and papercuts (ADR 0009)
- [ ] Phase 12: Soft generations and structured durable surfaces (ADR 0009)

**Exit criteria:**
- Only if phases 0–8 exit criteria pass daily use
- Document which subsets shipped
- Core Pi-Lisptc remains valuable if only phases 0–8 ship

---

## Timeline (estimate)

| Phase | Estimate | Dependencies |
|-------|----------|--------------|
| 0 | 1–2 days | None |
| 1 | 2–3 days | Phase 0 |
| 2 | 2–3 days | Phase 1 |
| 3 | 2–3 days | Phase 2 |
| 4 | 3–4 days | Phase 3 |
| 5 | 1–2 days | Phase 4 |
| 6 | 2–3 days | Phase 5 |
| 7 | 3–4 days | Phase 6 |
| 8 | 2–3 days (optional) | Phase 7 |
| 9–12 | 5–10 days (optional) | Phase 8 |

**Total (core path):** ~18–24 days of focused work

---

## Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Prompt bloat | High | Truncate interpreter source; use cache; prioritize Pi DNA |
| REPL corruption | High | Validate-before-eval; retry budget; sandbox eval |
| Vestige recall bloat | Medium | Top-k ranking; token budget; replace-not-accumulate |
| Provider fallback fails | Medium | Explicit capability registry; log mode selection; fail fast |
| `smart_ingest` noise | Medium | Gating rules; dedup; confidence threshold; user approval |

---

## Success metrics

- **Daily use:** Pi-Lisptc `lisp-mind` profile works for daily coding tasks
- **No regression:** `pi-default` profile retains stock Pi coding ability
- **Living mind:** Session REPL holds skills/state; durable facts in Vestige
- **Relevant recall:** Host auto-recalls from Vestige; injects top-k; does not dump whole memory
- **No image trash:** Validate/parse before session eval; retries; optional sandbox
- **Any major provider:** Works with Fireworks, OpenAI, Anthropic
- **Readable UX:** `(reply)` / `(halt)` + host pretty-print
- **Self-improvement without noise:** Mind epilogue → gated `smart_ingest`; reify replaces turn set; pins capped

---

## Next steps

1. Start with Phase 0 (baseline & profiles)
2. Follow phased plan with exit criteria
3. Document progress in `plan/VERIFY-LOG.md`
4. Pin upstream commits in `docs/UPSTREAM-PINS.md`
