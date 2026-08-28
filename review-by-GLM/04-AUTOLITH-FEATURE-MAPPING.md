# Review-by-GLM5p3 — Autolith Feature Mapping

Detailed mapping of Autolith patterns to Pi-Lisptc phases, with feasibility and adaptation notes.

---

## Mapping Overview

| Autolith Feature | Pi-Lisptc Phase | Feasibility | Adaptation Effort | Priority |
|-----------------|----------------|-------------|-------------------|----------|
| Context contribution system | 9 | High | Medium | P0 |
| Memory recall contributor | 7 (core) / 9 (refined) | High | Low | P0 |
| Prompt cache architecture | **New (pre-Phase 1)** | High | Low | P0 |
| Revision-gated resources | 9 | Medium | High | P1 |
| Tool lifecycle properties | 4/8 | Medium | Medium | P1 |
| Bounded RLM | 10 | Low (blocking constraint) | High | P2 |
| Content-addressed context | 10 | Medium | Medium | P2 |
| Agenda surface | 11 | High | Low | P2 |
| Papercut surface | 11 | High | Low | P2 |
| Soft generations/snapshots | 12 | High | Low | P2 |
| Skill loading | 12 | Medium | Medium | P3 |
| Self-modification safety | **Out of scope** | N/A | N/A | N/A |
| Recovery image | **Out of scope** | N/A | N/A | N/A |
| Private mutation repos | **Out of scope** | N/A | N/A | N/A |
| SBCL worker isolation | **Out of scope** | N/A | N/A | N/A |

---

## 1. Context Contribution System → Phase 9

### Autolith Source: `src/agent/context.lisp` (1064 lines)

### What It Does
A registry of functions that return structured "contributions" to the provider request. Each contribution has metadata (priority, lifetime, class) and content (instruction, evidence). A resolution pipeline invokes all contributors, deduplicates, resolves conflicts, fits a budget, and renders the final text.

### Pi-Lisptc Adaptation

**Language:** TypeScript (host-side), not Lisp. Contributors are TypeScript functions registered in the Pi extension.

**Schema:**
```typescript
interface ContextContribution {
  id: string;
  instruction: string;      // max 4000 chars
  evidence?: string;        // max 2000 chars
  priority: number;         // higher = more important
  lifetime: 'turn' | 'next-request';
  cls: 'mandatory' | 'advice';
  deduplicationKey?: string;
  supersedes?: string[];     // ids this supersedes
  conflictGroup?: string;   // items in same group compete
}

interface ContextDelivery {
  contributions: ContextContribution[];
  omitted: { id: string; reason: string }[];
  failures: { contributor: string; error: string }[];
  renderedText: string;
}
```

**Budget:**
- Mandatory total: 8,000 characters hard cap
- Advisory budget: 2,000 tokens (~8,000 chars at 4 chars/token)

**Built-in Contributors (v1):**
1. `related-memories` — Vestige recall, refactored from Phase 7
2. `recent-user-ops` — Ring buffer of last 8-16 validated evals
3. `mind-active` — Compact dump of user/pins/project

**Injection Point:** Trailing developer message, NOT in system prompt.

### Feasibility: HIGH
- No dependency on SBCL or any Common Lisp feature
- Pure TypeScript, runs in Pi extension
- Autolith's resolution pipeline is well-documented and can be ported line-by-line

### Estimated Effort: 3-5 days

---

## 2. Memory-Related Context → Phase 7 (core) / Phase 9 (refined)

### Autolith Source: `src/agent/memory-context.lisp` (83 lines)

### What It Does
Extracts retrieval terms from the latest user message (filtering stop words <3 chars and 24 common English words), ranks memories by weighted lexical relevance, returns top 6 as a context contribution.

### Pi-Lisptc Adaptation

Phase 7 implements this directly in the host (TypeScript) without the contributor framework:
```typescript
// Phase 7: Direct implementation
async function recallForUserMessage(text: string, cwd: string): Promise<RecallHit[]> {
  const terms = extractTerms(text); // stop word filtering
  const results = await vestigeAdapter.recall(terms.join(' '), 6, 180);
  return results;
}
```

Phase 9 refactors into the contributor framework:
```typescript
// Phase 9: As contributor
registerContributor('related-memories', async (ctx) => {
  const terms = extractTerms(ctx.latestUserMessage);
  const hits = await vestigeAdapter.recall(terms.join(' '), 6, 180);
  return [{
    id: 'related-memories',
    instruction: 'Related memories from your durable store:',
    evidence: hits.map(h => h.excerpt).join('\n'),
    priority: 25,
    lifetime: 'turn',
    cls: 'advice'
  }];
});
```

### Feasibility: HIGH
- Vestige MCP already provides recall
- Stop word filtering is trivial
- Lexical ranking is simpler than semantic but sufficient for v1

---

## 3. Prompt Cache Architecture → NEW (before Phase 1)

### Autolith Source: `docs/context-cost-report.org` (356 lines)

### What It Does
Quantitative analysis proving that mutable session state in the system prompt is the primary source of cache waste.

### Pi-Lisptc Adaptation

This is not a phase — it's a cross-cutting architectural principle that affects every phase.

**Implementation:**
1. Phase 1: Split merged prompt into stable (Layer 0) and volatile (Layer 2) regions
2. Phase 7: Deliver mind_active as trailing message, not in system prompt
3. Phase 9: Context contributions rendered in Layer 2

**Token Savings Estimate:**
- Current plan: Full prompt (~20k tokens) re-sent and re-processed every turn
- With cache: Layer 0 (~20k tokens) cached, Layer 2 (~2k tokens) per turn
- Savings: ~18k tokens per turn after first turn
- Over 10-turn session: ~180k tokens saved

### Feasibility: HIGH
- Requires Pi to support trailing messages (developer role or similar)
- If Pi doesn't support this, wrap the volatile content in a user message with a distinctive prefix

---

## 4. Revision-Gated Resources → Phase 9

### Autolith Source: `src/resource/protocol.lisp` (469 lines), `src/resource/memory.lisp` (742 lines)

### What It Does
Every mutable resource read returns an opaque revision identifier. Edits require the revision from the prior read. Stale edits are rejected.

### Pi-Lisptc Adaptation

For v1, Pi-Lisptc's primary mutable resource is the agent's own files (workspace). MCP's `fs/write` already provides read-then-write patterns.

**Implementation for mind state:**
- `mind/note!` returns a revision ID
- `mind/update!` requires the revision ID
- This prevents concurrent mind mutations (e.g., from RLM sub-calls)

**Effort:** Medium. The pattern is clear but applying it to every mind operation requires discipline.

### Feasibility: MEDIUM
- Pi-Lisptc's mind state is primarily in-memory (REPL bindings), not file-backed
- Revision gating is most valuable for file-backed resources (workspace files, prelude)
- For in-memory state, the single-threaded Node model provides natural serialization

---

## 5. Tool Lifecycle Properties → Phase 4/8

### Autolith Source: `src/tools/registry.lisp` (1004 lines)

### What It Does
Every tool has behavioral metadata: persistence, barrier, execution policy, child safety, compaction visibility.

### Pi-Lisptc Adaptation

In lisp-mind profile, MCP tools are Lisp functions, not JSON tools. The "tool lifecycle" maps to Lisp function metadata:

```lisp
(defparameter *tool-metadata*
  (make-hash-table :test #'equal))

(defun register-tool-meta (name &key barrier-p exclusive-p destructive-p)
  (setf (gethash name *tool-metadata*)
        (list :barrier-p barrier-p
              :exclusive-p exclusive-p
              :destructive-p destructive-p)))
```

**Key properties for Pi-Lisptc:**
- `:barrier-p` — Must complete before subsequent tools (e.g., `mind/reify!` before any action)
- `:exclusive-p` — Cannot run concurrently with other tools (e.g., file writes)
- `:destructive-p` — Modifies external state (triggers confirm/snapshot)

### Feasibility: MEDIUM
- lisptc doesn't have a tool registry (MCP tools are dynamically bound)
- Adding metadata requires wrapping `installServer` or post-processing
- For v1, hardcode metadata for known tools (Vestige, filesystem)

---

## 6. Bounded RLM → Phase 10

### Autolith Source: `docs/rlm.org`, `src/worker/lisp.lisp` (554 lines)

### What It Does
Treating long context as external environment. Sub-requests with budget accounting (calls, tokens, depth). Content-addressed objects for large context.

### Pi-Lisptc Adaptation

**Critical Blocking Issue:** lisptc's interpreter blocks the main thread via `Atomics.wait`. An RLM sub-request would need to:
1. Make an HTTP request to the provider (async)
2. Wait for the response
3. Eval the response in the interpreter

But step 1 requires the event loop, which is blocked by `Atomics.wait` in the parent call.

**Resolution:** RLM must bypass the interpreter's jobs runtime. The host (TypeScript) makes the provider request directly, then feeds the response to the interpreter for evaluation.

```typescript
// Host-side RLM implementation
async function mindInfer(
  query: string,
  budget: { calls: number; tokens: number; depth: number }
): Promise<string> {
  // Make provider request directly (not through MCP/interpreter)
  const response = await pi.provider.complete({
    messages: [{ role: 'user', content: query }],
    maxTokens: budget.tokens
  });
  return response.content;
}
```

### Feasibility: LOW
- Requires significant architectural work (bypass jobs runtime)
- Budget accounting must be host-enforced
- Depth tracking requires call stack management
- Correctly deferred to Phase 10 with measured-need gate

---

## 7. Agenda Surface → Phase 11

### Autolith Source: `src/resource/agenda.lisp` (512 lines), `src/state/agendas.lisp` (694 lines)

### What It Does
Workspace-scoped todo list with status tracking, memory cross-references, and revision-gated editing.

### Pi-Lisptc Adaptation

**Implementation:**
- `*mind/agenda*` — in-memory alist in the REPL
- Vestige-backed persistence: `mind/agenda!` calls `smart_ingest` with `agenda` tag
- Bootstrap recall: query with `agenda` tag on session start

**Key simplification vs Autolith:**
- No revision-gated editing for v1 (agenda items are small)
- No memory cross-references for v1
- No workspace-scoped isolation for v1

```lisp
(defun mind/agenda! (action &rest args)
  (ecase action
    (:add (let ((item (list :id (gensym "AG-")
                          :title (car args)
                          :status :todo
                          :updated (get-universal-time))))
            (push item *mind/agenda*)
            (mind/note! (format nil "Agenda: ~a" (car args))
                       :tags '(agenda))))
    (:list (reverse *mind/agenda*))
    (:update ...)
    (:remove ...)))
```

### Feasibility: HIGH
- Simple data structure (alist of items)
- Vestige provides persistence
- No blocking issues

---

## 8. Papercut Surface → Phase 11

### Autolith Source: `src/resource/papercut.lisp` (647 lines), `src/state/papercuts.lisp` (454 lines)

### What It Does
Lightweight defect reporting. Papercuts have title, content, resolution, and tombstone-based closure.

### Pi-Lisptc Adaptation

Nearly identical to agenda — `*mind/papercuts*` as in-memory alist, Vestige-backed persistence.

**Key feature from Autolith:** Closure requires a resolution text. This prevents "drive-by" bug reports without resolution.

### Feasibility: HIGH

---

## 9. Soft Generations → Phase 12

### Autolith Source: `src/state/generations.lisp` (535 lines), `src/state/image-commits.lisp` (1236 lines)

### What It Does
Save points of the live image with complete replay scripts. Recovery from any saved state.

### Pi-Lisptc Adaptation

**Dramatically simplified:**
- Snapshot = serialize `*mind/user*`, `*mind/pins*`, `*mind/project*`, skill metadata to a `.sexp` file
- Restore = `read` + `eval` each form
- No private Git repos
- No SBCL image save
- No recovery image

```lisp
(defun mind/snapshot! (&optional (path ".lisptc/snapshots/"))
  (let ((snapshot (list (cons '*mind/user* *mind/user*)
                        (cons '*mind/pins* *mind/pins*)
                        (cons '*mind/project* *mind/project*))))
    (with-open-file (out (merge-pathnames
                           (format nil "snapshot-~a.sexp"
                                   (get-universal-time))
                           path)
                          :direction :output :if-exists :supersede)
      (print snapshot out))))
```

**Lobotomy mitigation:** Before snapshot, commit all successful defuns from the current session to prelude files.

### Feasibility: HIGH
- Standard Lisp serialization
- No exotic dependencies
- Restore may fail if definitions reference MCP tools not yet loaded — document this

---

## 10. Skill Loading → Phase 12

### Autolith Source: `src/skills/runtime.lisp` (615 lines), `src/skills/tools.lisp` (100 lines)

### What It Does
Named bundles of request-local instructions. Content-addressed caching. Model selects from catalog.

### Pi-Lisptc Adaptation

**Simplest approach:**
- Skills = `.lisp` files in `.lisptc/skills/`
- `mind/load-skill!` reads and evals the file
- Skill content is Lisp code (definitions + instructions as docstrings)

**No need for:**
- Content-addressed caching (Node's fs cache is sufficient)
- YAML frontmatter (use Lisp `defvar` + docstring)
- Catalog building (directory listing is sufficient)

### Feasibility: MEDIUM
- Simple implementation
- But skills that define new MCP tool compositions require careful ordering
- The `:provider-round-trip-barrier-p` concept from Autolith should be adopted
