# ADR Recommendations (Gemini)

## Proposed new ADRs

### ADR 0010: Host-side contributor registry (phase 9)

**Status:** Proposed

**Context:** Autolith injects request-local context via contributors. Phase 7 already forces Vestige recall + reify; a general contributor registry extends that pattern without requiring the model to opt in.

**Decision:**
1. After phases 0–8 are stable, add a host-side contributor registry in the Pi-Lisptc extension.
2. Each contributor returns structured contributions: `id`, `instruction` (trusted), optional `evidence` (untrusted excerpts), `priority`, `lifetime` (`:turn` | `:next-request` | `:while-relevant`), `class` (`:mandatory` | `:advice`).
3. **Mandatory** contributions always attach (subject to hard char cap). **Advice** competes for a small token budget (~1.5k tokens default).
4. Built-in contributors (minimum): related-memories (phase 7 path, re-framed as contributor), recent-user-ops (last N validated Lisp results), mind_active summary from reify.
5. Do not port Autolith's full CLOS contributor machinery or sexp-store; keep TypeScript/host + thin Lisp hooks.

**Consequences:**
- Extends phase 7 without rewriting its exit criteria.
- Requires injection point in Pi prompt assembly (developer/system trailing block or user-context field).
- Advice budget prevents contributor spam from drowning coding DNA (ADR 0001).

---

### ADR 0011: Bounded RLM as optional Lisp operations (phase 10)

**Status:** Proposed

**Context:** Autolith and Prime-style agents treat oversized context as an environment: the model decomposes work, runs bounded sub-inferences, and returns values without stuffing the entire corpus into the parent prompt.

**Decision:**
1. Do not implement RLM in phases 0–8.
2. When long-context tasks fail with phase-7 memory alone, add optional Lisp operations in the mind image: `(mind/infer prompt &key context contract budget)`, `(mind/map prompts &key context budget)`.
3. Context designators: pathname, Vestige id, string literal, or `{ :label :digest :path }` descriptor — body stays outside the parent model context when large.
4. Budgets are host-enforced (max calls, tokens, depth). Exceeding budget returns error to the parent REPL, not silent continuation.
5. Sub-frames must not pollute the parent conversation history or the main REPL bindings except via the returned value.

**Consequences:**
- Provider cost and latency increase when used; default coding path remains single-turn Lisp.
- Needs clear prompt policy: use RLM only for corpus-scale tasks, not routine edits.
- Aligns with phase 8 sandbox direction for isolation.

---

### ADR 0012: Agendas and papercuts (phase 11)

**Status:** Proposed

**Context:** Autolith separates durable surfaces (conversations, memories, agendas, papercuts). Pi-Lisptc uses Vestige as the cabinet and the lisptc REPL as cortex.

**Decision:**
1. **Agendas** (optional): versioned workspace plan as `*mind/agenda*` plus Vestige-backed entries tagged `agenda`. Host helpers load/save; model updates via gated `mind/agenda!`.
2. **Papercuts** (optional): user-visible defects recorded with evidence via `mind/papercut!` → Vestige; close with tombstone metadata. Not a second bug tracker—thin durable notes.
3. **Soft generations** (optional): on session_start or explicit `(mind/snapshot!)`, persist prelude + pins + prefs to a dated snapshot under project or XDG data. Restore is load-into-REPL, not process reboot into a recovery core.
4. Reject Autolith-style private mutation repos and recovery-image boot loops inside this extension.

**Consequences:**
- Gives structured evolution beyond free-form `note!` without adopting Autolith's full state taxonomy.
- Snapshot/restore is best-effort continuity, not crash-proof agent OS semantics.
- Keeps cabinet = Vestige; does not invent a parallel sexp-store.

---

### ADR 0013: Audit manifest per turn

**Status:** Proposed

**Context:** Diagnostics and reproducibility require per-turn audit logging.

**Decision:**
1. Every turn records audit manifest: `turnId`, `timestamp`, `profile`, `provider`, `mode`, `recallQuery`, `recallResults`, `reificationForm`, `evalResult`, `mcpCalls`, `smartIngestCandidates`, `smartIngestDecision`, `smartIngestReason`.
2. Audit manifest is logged to disk (optional) and available for host diagnostics.
3. Audit manifest is used for test coverage (Gate 1–5) and reproducibility.

**Consequences:**
- Disk usage increases; rotate logs after N days.
- Audit manifest is useful for debugging and reproducibility.
- No performance impact on critical path (async logging).

---

### ADR 0014: Minimal bootstrap allowlist for `lisp-mind`

**Status:** Proposed

**Context:** `lisp-mind` profile must deny broad outer action dispatch except minimal bootstrap/control allowlist.

**Decision:**
1. Define minimal bootstrap allowlist explicitly in `action-channel.ts`:
   ```ts
   const LISP_MIND_ALLOWLIST = [
     'opencode-go-cache', // approved direct extension
     // ... other minimal bootstrap/control tools
   ];
   ```
2. `lisp-mind` profile denies all other outer tools.
3. MCP calls from Lisp actions are schema-validated, profile-authorized, budgeted, audited.

**Consequences:**
- Forced action channel works as intended.
- No regression in `pi-default` tools.
- Clear boundary between profiles.

---

## Existing ADRs (review)

| ADR | Status | Assessment | Notes |
|-----|--------|------------|-------|
| 0001: Merge prompt not replace | ✅ Accepted | Strong | Correctly mandates merge, not replace. |
| 0002: Vestige cabinet / lisptc cortex | ✅ Accepted | Strong | Right split; reify per turn is critical. |
| 0003: Validate before eval | ✅ Accepted | Strong | Essential for image safety. |
| 0004: Reify replaces turn retrieval | ✅ Accepted | Strong | Prevents memory bloat. |
| 0005: Provider modes | ✅ Accepted | Strong | Pragmatic; capability registry needed. |
| 0006: Two profiles | ✅ Accepted | Strong | Right boundary; document launch paths. |
| 0007: Context contributors | ⚠️ Proposed | Good | Additive after phase 8; do not port Autolith runtime. |
| 0008: Bounded RLM | ⚠️ Proposed | Good | Only if phase 7 fails on long-context tasks. |
| 0009: Soft generations | ⚠️ Proposed | Good | Structured evolution; not crash-proof agent OS. |

---

## Related documents

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Execution roadmap](EXECUTION-ROADMAP.md)
- [Interfaces and invariants](INTERFACES-AND-INVARIANTS.md)
- [Test strategy](TEST-STRATEGY.md)
