# Pi-Lisptc Architecture Review (Gemini)

## Executive summary

Pi-Lisptc is a well-scoped, high-leverage enhancement of Pi that embeds a forced programmatic mind (lisptc REPL) plus durable associative memory (Vestige) without discarding Pi's coding performance. The plan correctly identifies the core failure modes of current AI coding agents (coherence loss, optional memory ignored, prompt bloat, provider lock-in) and proposes a pragmatic, phased solution.

**Key strengths:**
- Clear problem statement and goals (G1–G9) with measurable success signals
- Phased implementation plan with explicit non-goals
- Strong ADRs for critical decisions (merge-prompt, validate-before-eval, reify-replace)
- Grounded in actual upstream codebases (lisptc `apps/pi`, `packages/interpreter`)
- Additive Autolith track (phases 9–12) that avoids platform porting

**Key risks:**
- Prompt assembly complexity and token budget management
- REPL state hygiene and reification safety
- Provider mode composition and fallback paths
- Vestige integration and host-side orchestration

**Overall verdict:** Architecture is sound and implementable. The main gaps are in test strategy, interface contracts, and operational details for the host extension. This review fills those gaps with concrete recommendations.

---

## Goals and substrate analysis

### Goals (G1–G9)

| Goal | Assessment | Notes |
|------|------------|-------|
| **G1** Keep Pi coding ability | ✅ Strong | ADR 0001 correctly mandates merge, not replace. Pi prompt DNA (role, AGENTS.md, cwd, path conventions) must remain foundational. |
| **G2** Forced action channel | ⚠️ Needs detail | `lisp-mind` profile must deny broad outer tools; only MCP-in-image via validated Lisp. Define minimal bootstrap allowlist. |
| **G3** Living mind | ✅ Strong | REPL as cortex + Vestige as cabinet is the right split. Reify per turn is critical. |
| **G4** Relevant recall | ⚠️ Needs detail | Host auto-recall + top-k injection is correct. Must define ranking, budget, and scope filters. |
| **G5** No image trash | ✅ Strong | Validate-before-eval (ADR 0003) is essential. Retry budget 2–3 is reasonable. |
| **G6** Any major provider | ✅ Strong | Three modes (grammar, strict-tool, validate+retry) with capability registry is pragmatic. |
| **G7** Readable UX | ⚠️ Needs detail | `(reply)` / `(halt)` protocol is good. Host pretty-printer and UX prefs need spec. |
| **G8** Self-improvement without noise | ⚠️ Needs detail | `smart_ingest` gating is critical. Define caps for pins, skills, lessons. |
| **G9** Two profiles | ✅ Strong | `lisp-mind` vs `pi-default` is the right boundary. Document launch paths clearly. |

### Substrate analysis

#### lisptc upstream (`1hachem/lisptc`)

- **`apps/pi/extension/lisp-repl.ts`** (15.6KB) — Persistent session lifecycle, controlled evaluation. This is the core of the forced action channel. Key hooks: session start, eval, result streaming, cancellation.
- **`apps/pi/extension/system-prompt.ts`** (5.7KB) — Prompt assembly. Currently returns `{ systemPrompt, tools }`. Must be rewritten to merge Pi prompt + lisptc channel + interpreter source (ADR 0001).
- **`packages/interpreter/src/lisp.ts`** (73KB) — Lisp engine, parser, evaluator. This is the reusable interpreter. Minimal diffs needed for Pi-Lisptc.
- **`packages/interpreter/src/mcp.ts`** (27KB), **`mcp-broker.ts`** (12KB), **`mcp-oauth.ts`** (12KB) — MCP invocation, OAuth, secrets. These are the capability bridges for MCP-in-image.
- **`packages/interpreter/src/jobs.ts`** (13KB), **`jobs-broker.ts`** (8KB) — Background job orchestration. Useful for async MCP calls, but not required for v1.
- **`packages/interpreter/src/secrets.ts`** (8KB) — Secret management. Needed for MCP OAuth flows.
- **`packages/interpreter/src/grammar.ts`** (1KB), **`lisptc.gbnf`** (1KB) — Grammar constraints for Fireworks and similar providers.

**Key insight:** The lisptc `apps/pi` extension is already the right host for Pi-Lisptc. The plan should extend `lisp-repl.ts` and `system-prompt.ts` rather than building a separate daemon.

#### Vestige (`samvallad33/vestige`)

- Local MCP memory server with recall, smart_ingest, FSRS ranking.
- Pi-Lisptc must orchestrate recall → reify → act → ingest loop at the host level, not rely on Vestige prompt protocol alone.

#### Autolith (`lambda-symbolics/autolith`)

- Inspiration for context contributors, RLM, agendas, papercuts.
- **Do not port** Autolith runtime, sexp-store, or SBCL image model.
- Adapt behaviors and interfaces only (phases 9–12).

---

## Critical decisions and recommendations

### 1. Prompt assembly (ADR 0001)

**Decision:** Merge Pi prompt + lisptc channel + full interpreter source. Never stock-replace.

**Recommendation:**
- Compose asymmetric prompt in `system-prompt.ts`:
  ```
  Pi invariant system prompt
  + Pi coding role and safety/runtime instructions
  + AGENTS.md instructions
  + cwd, repository, files, diagnostics, path conventions
  + current task
  + lisp-mind action contract
  + bounded retrieved Vestige context or recall manifest
  ```
- Pi portion is foundational. Mind profile adds action-language contract but may not replace Pi's coding identity.
- Mitigate token bloat with cache and large context. Consider truncating interpreter source for non-Fireworks providers.

### 2. Forced action channel (G2)

**Decision:** In `lisp-mind`, actions go through Lisp eval (MCP-in-image), not 50 outer tools.

**Recommendation:**
- Three enforcement layers:
  1. **Generation:** grammar-constrained Lisp (Fireworks) | strict structured output | parse/validate/retry (others)
  2. **Profile runtime policy:** `lisp-mind` denies normal broad outer action dispatch except minimal bootstrap/control allowlist and approved direct extensions (e.g., `opencode-go-cache`)
  3. **Evaluation:** only persistent Lisp session receives capability bridge; each MCP call is schema-validated, profile-authorized, budgeted, audited
- Define minimal bootstrap allowlist explicitly in `profiles.ts` or `action-channel.ts`.

### 3. Validate-before-eval (ADR 0003)

**Decision:** Strip markdown fences, parse/read (and optional GBNF check) before any session eval. On failure: do not eval; retry with error feedback (budget 2–3).

**Recommendation:**
- Implement in `lisp-repl.ts` as a pre-eval pipeline:
  ```
  raw model output
    -> strip markdown fences
    -> parse to Lisp AST (lisp.ts)
    -> optional GBNF check (grammar.ts)
    -> validate allowlist (only trusted forms)
    -> eval in session
  ```
- Never evaluate raw text fields from memory or model output.
- Retry budget 2–3 is reasonable. Log failures for diagnostics.

### 4. Reify-replace-not-accumulate (ADR 0004)

**Decision:** `*mind/retrieved*` is replaced every user-turn recall. Prefs: small key merge only. Pins/lessons: capped ring.

**Recommendation:**
- Host constructs data-only literal passed to trusted prelude function:
  ```lisp
  (mind.replace-turn-recall
    '(:turn-id "turn-0042"
      :items
      ((:id "ves_001"
        :kind :project-fact
        :text "The repository uses pnpm workspaces."
        :scope :workspace
        :confidence 0.94
        :source (:kind :file :path "pnpm-workspace.yaml")
        :tags ("build" "tooling")))))
  ```
- Prelude maintains `*mind-turn-recall*` plus index. Action program uses explicit APIs: `(mind.recall-all)`, `(mind.recall-by-tag "architecture")`, etc.
- At turn start: clear previous transient recall set, install new top-k, preserve only explicitly pinned items within hard cap, record audit manifest.

### 5. Provider modes (ADR 0005)

**Decision:** Select mode per provider/model capability. Compose with cache extension. Always host-validate before eval.

**Recommendation:**
- Capability registry (simple table OK for v1):
  ```ts
  type ProviderMode = 'grammar' | 'strict-tool' | 'validate-retry';
  const capabilityTable: Record<string, ProviderMode> = {
    'fireworks/llama-3.1-8b': 'grammar',
    'openai/gpt-4o': 'validate-retry',
    'anthropic/claude-3.5-sonnet': 'validate-retry',
  };
  ```
- Retry path is first-class, not a fallback afterthought.
- Cache extension (`opencode-go-cache`) composes with any mode. Cache mutations first, then validate.

### 6. Two profiles (ADR 0006)

**Decision:** `pi-default` (no lisptc mind loop; normal tools) vs `lisp-mind` (merged prompt; tools empty/minimal; MCP-in-image; reify loop).

**Recommendation:**
- Launch via scripts/aliases or Pi settings profiles.
- Document both clearly in README and scripts.
- Do not half-enable 50 outer MCP tools under Lisp-only prompt.

---

## Risks and mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Prompt bloat exceeds context window | High | Truncate interpreter source for non-Fireworks providers; use cache; prioritize Pi DNA over lisptc details. |
| REPL state corruption from malformed eval | High | Validate-before-eval pipeline; retry budget; optional sandbox eval (phase 8). |
| Vestige recall dumps too much into prompt/REPL | Medium | Top-k ranking with token budget; replace-not-accumulate; scope/sensitivity filters. |
| Provider mode fallback fails silently | Medium | Explicit capability registry; log mode selection; fail fast on unsupported providers. |
| `smart_ingest` writes noise to durable memory | Medium | Gating rules: dedup, scope, confidence threshold, user approval for high-impact writes. |
| Profile confusion (user launches wrong mode) | Low | Clear scripts/aliases; Pi settings UI integration; warning on first `lisp-mind` launch. |

---

## Recommended architecture (diagram)

```
User message
    │
    ├─► Host (Pi extension: apps/pi/extension)
    │   ├─ buildSystemPrompt (Pi DNA + lisptc channel + interpreter source)
    │   ├─ Vestige recall (auto, top-k, ranking, budget)
    │   ├─ reify! (mind.replace-turn-recall in persistent REPL)
    │   └─ provider policy (grammar | strict-tool | validate-retry)
    │
    ▼
Model (merged Pi coding + lisptc channel + interpreter source)
    │  output = Lisp only (lisp-mind profile)
    ▼
Validate → eval in REPL (apps/pi/extension/lisp-repl.ts)
    │
    ├─► MCP tools as Lisp functions (packages/interpreter/src/mcp.ts)
    │   ├─ OAuth/secrets (mcp-oauth.ts, secrets.ts)
    │   └─ jobs (jobs.ts, optional)
    │
    ├─► (reply …) / pretty-print (+ host UX prefs)
    └─► mind epilogue → smart_ingest | skip (gated)
        └─► Vestige ingest (durable, capped)
```

---

## Upstream pinning

| Project | Commit SHA (pin) | Role |
|---------|------------------|------|
| `1hachem/lisptc` | `b2ca6a5946cfc054731ff0d882db17b1867a3d55` (Aug 2026) | Core interpreter, Pi extension |
| `lambda-symbolics/autolith` | (TBD) | Inspiration only |
| `samvallad33/vestige` | (TBD) | Durable memory |
| `earendil-works/pi` | (TBD) | Agent harness |

Pin commit SHAs in `docs/UPSTREAM-PINS.md` when implementing phases 0–8 for reference, not as hard dependencies.

---

## Conclusion

Pi-Lisptc architecture is sound, pragmatic, and implementable. The main gaps are in test strategy, interface contracts, and operational details for the host extension. This review fills those gaps with concrete recommendations. Follow the phased plan (EXECUTION-ROADMAP.md) with exit criteria, and you will have a working, durable mind-enhanced Pi agent.
