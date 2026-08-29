# Review-by-All — Interfaces and Invariants

Synthesized from all five reviews.

---
## 1. Pi Extension Hooks (Verified Against Source)

| Hook | Current Behavior | Required Change | Invariant |
|------|----------------|-----------------|----------|
| `session_start` | `pi.setActiveTools([])`, init LispEditor | Only in `lisp-mind` profile | **I-PI-1:** pi-default must NOT clear tools or modify prompt |
| `before_agent_start` | Returns `{ systemPrompt: SYSTEM_PROMPT }` (replace) | Return merged prompt (Layer 0) via customPrompt | **I-PI-2:** Project context still appended by Pi |
| `before_provider_request` | Unconditionally adds Fireworks grammar | Conditional: grammar/tool-call/retry + cache fields | **I-PI-3:** Cache fields never stripped |
| `message_end` | Evals text → resets on exception | Strip fences → validate → eval → inject result | **I-PI-4:** Never eval on parse failure | **I-PI-5:** Never reset on EvalException |

## 2. Capability Result Type (from Terra)

```typescript
type CapabilityResult<T> =
  | { ok: true; value: T; usage: Usage; auditEventId: string }
  | { ok: false;
    code: 'DENIED' | 'INVALID' | 'BUDGET' | 'UNAVAILABLE' | 'FAILED' | 'CANCELLED';
    message: string; auditEventId: string };
```

## 3. Profile Type (from Terra)

```typescript
interface Profile {
  id: string;
  version: string;
  enabledContributors: string[];
  capabilityGrants: Array<{
    capability: string;
    operations: string[];
  }>;
  contextBudget: {
    maxTokens: number;
    reserveTokens?: number;
  };
  providerPolicy: {
    preferred: string[];
    requiredCapabilities: string[];
  };
  persistencePolicy: 'off' | 'ephemeral' | 'durable';
  approvalPolicy: {
    requiredFor: string[];
  };
}
```

## 4. Context Contribution (from Autolith + Luna + Terra)

```typescript
interface ContextContribution {
  id: string;
  instruction: string;       // max 4000 chars
  evidence?: string;         // max 2000 chars
  priority: number;          // higher = more important
  lifetime: 'turn' | 'next-request';
  cls: 'mandatory' | 'advice';
  deduplicationKey?: string;
  supersedes?: string[];
  conflictGroup?: string;
  // From Luna:
  tokenCost?: number;
  source?: string;
  ttl?: number;
}
```

**Budget rules (verified from Autolith):**
- Mandatory total: 8,000 characters hard cap
- Advisory: ~1,500 tokens (~8,000 chars)
- Mandatory always included (subject to cap)
- Advisory sorted by priority, drops low-priority when over budget

## 5. Vestige Adapter (from GLM5p3 + Sonnet)

```typescript
interface RecallHit {
  id: string;
  title: string;
  excerpt: string;      // max 180 chars
  score: number;         // relevance score
  tags: string[];
  updatedAt: string;
}

interface VestigeAdapter {
  recall(query: string, k: number, maxChars: number): Promise<RecallHit[]>;
  ingest(entry: { content: string; tags?: string[]; evidence?: string }): Promise<boolean>;
  version(): Promise<string>;
  isHealthy(): Promise<boolean>;
}
```

**Invariants:**
- **I-VESTIGE-1:** recall never throws. Returns empty array on failure.
- **I-VESTIGE-2:** ingest returns false on rate limit/failure. Never throws.
- **I-VESTIGE-3:** Results below quality threshold (score < 0.1) filtered.
- **I-VESTIGE-4:** Adapter isolates from tool name changes via version detection.

## 6. Mind API (Lisp — from Gemini + Terra)

**Core (phases 6-7):**
- `mind.replace-turn-recall` — replaces turn recall data (Terra's allowlisted function)
- `mind.recall-all` — returns all current items
- `mind.recall-by-tag` — filter by tag
- `mind.recall-by-kind` — filter by kind
- `mind.recall-get` — get by ID
- `mind.recall-search` — text search
- `mind/note!` — gated durable ingest (evidence required, 3/turn)
- `mind/prefer!` — update user preference
- `mind/fail!` — record failure with evidence
- `mind/skip!` — skip epilogue
- `mind/reify!` — bridge function (replaces retrieved, merges prefs)

**Special Variables:**
- `*mind/retrieved*` — replaced every turn, never accumulated, max 6 items, ~2k chars
- `*mind/pins*` — capped ring, max 40
- `*mind/user*` — small key/value, persisted to disk
- `*mind/ux*` — presentation preferences
- `*mind/project*` — project invariants
- `*mind/skills*` — registered callable metadata, max 30
- `*mind/max-pins*` — default 40

## 7. Validation Pipeline (from Luna + Terra + Sonnet)

```
Raw model output
  → 1. Strip thinking parts
  → 2. Strip markdown fences
  → 3. Parse (lisptc reader)
  → 4. Allowlist check (only safe forms)
  →  → On failure: inject error, retry (up to N), NEVER eval
  → 5. Eval in session
  →  → On EvalException: preserve definitions, report error (I-PI-5)
  →  → On catastrophic error: reset + prelude reload
```

## 8. Memory Safety Pipeline (from Terra + Gemini)

```
Vestige record
  → Schema validation
  → Scope/sensitivity filtering
  → Relevance ranking + item/token budget (top-k, score > 0.1)
  → Data-only Lisp serializer (quoted literals)
  → Parse to Lisp AST
  → Allowlist validation: only (mind.replace-turn-recall <quoted-literal>)
  → Evaluate in active session
```

**Anti-pattern:** `repl.eval(record.text)` is explicitly forbidden.

## 9. Prompt Layers (from GLM5p3 + Autolith)

**Layer 0: Stable System Prompt (cacheable)**
- Pi coding role + guidelines
- lisptc channel rules
- INTERPRETER_SOURCE_LLM (optimized subset)
- Changes only on: workspace switch, lisptc upgrade, Pi-Lisptc upgrade

**Layer 2: Volatile Mind State (per-turn, trailing message)**
- mind_active summary (*mind/retrieved*, pins, prefs)
- Context contributions (memories, recent ops)
- Changes every turn
- NEVER in system prompt prefix

## 10. Budget Type (from Terra)

```typescript
interface Budget {
  maxDepth: number;        // for RLM
  maxElapsedMs: number;    // for RLM or jobs
  maxModelCalls: number;   // per turn
  maxToolCalls: number;    // per turn
  maxInputTokens: number;  // per turn
  maxOutputTokens: number; // per turn
  maxCostUsd?: number;     // per turn
  maxGeneratedBytes?: number; // per materialization
}
```