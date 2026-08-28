# Review-by-GLM5p3 — Interfaces and Invariants

Contracts and invariants that the implementation must maintain.

---

## 1. Pi Extension Interface

### 1.1 Hooks Used

| Hook | Purpose | Invariant |
|------|---------|-----------|
| `session_start` | Clear tools, init REPL, setup editor | Must NOT throw. If it throws, the Pi session fails entirely. |
| `before_agent_start` | Return merged system prompt | Must return `{ systemPrompt: string }`. Pi appends project context after this. |
| `before_provider_request` | Inject cache fields + constraint mode | Must merge with other extensions' modifications. Must not overwrite cache fields. |
| `message_end` | Validate, eval, drive REPL loop | Must handle thinking-only responses (no Lisp). Must not block indefinitely. |

### 1.2 Extension API Surface

```typescript
interface PiLisptcExtension {
  // Called by Pi on session start
  sessionStart(pi: ExtensionAPI): void;
  
  // Called by Pi before each agent run
  beforeAgentStart(pi: ExtensionAPI): { systemPrompt: string };
  
  // Called by Pi before each provider request
  beforeProviderRequest(
    pi: ExtensionAPI, 
    request: ProviderRequest
  ): ProviderRequest;
  
  // Called by Pi when assistant message is complete
  messageEnd(pi: ExtensionAPI, entry: SessionEntry): MessageEndResult;
}
```

### 1.3 Invariants

- **I-PI-1:** `before_agent_start` NEVER returns only POLICY without project context. Pi's `buildSystemPrompt` must be verified to append project context when `customPrompt` is set.
- **I-PI-2:** `before_provider_request` NEVER strips cache fields set by `opencode-go-cache`.
- **I-PI-3:** `message_end` NEVER calls `repl.reset()` on `EvalException`. Reset only on catastrophic interpreter corruption.
- **I-PI-4:** The extension MUST work alongside `opencode-go-cache` without conflicts.

---

## 2. Mind API (Lisp)

### 2.1 Special Variables

| Variable | Type | Invariant |
|----------|------|-----------|
| `*mind/retrieved*` | list or nil | REPLACED each turn, never appended. Max 6 entries, ~2k chars total. |
| `*mind/user*` | alist or nil | Key/value pairs. Small. Persisted to disk. |
| `*mind/ux*` | alist or nil | Presentation preferences. |
| `*mind/pins*` | list | Capped ring, max `*mind/max-pins*` (40). Oldest evicted on overflow. |
| `*mind/project*` | alist or nil | Project invariants. Pinned, not evicted. |
| `*mind/skills*` | list | Registered callable metadata. Max 30. |
| `*mind/max-pins*` | integer | Default 40. Read-only after initialization. |

### 2.2 Core Functions

```lisp
;; Reify — the bridge from cabinet to cortex
(defun mind/reify! (&key retrieved merge-prefs) 
  "REPLACE *mind/retrieved* with RETRIEVED.
   If MERGE-PREFS, merge retrieved prefs into *mind/user*."
  ...)

;; Epilogue — end-of-turn mind operations
(defun mind/note! (content &key evidence tags)
  "Record a durable note to Vestige via smart_ingest.
   EVIDENCE is required (string). RATE LIMITED (3/turn)."
  ...)

(defun mind/prefer! (key value)
  "Update a user preference. Persisted to disk."
  ...)

(defun mind/fail! (description &key evidence)
  "Record a failure with evidence for future avoidance."
  ...)

(defun mind/skip! (&optional reason)
  "Skip mind epilogue for this turn. Log REASON."
  ...)
```

### 2.3 Invariants

- **I-MIND-1:** `*mind/retrieved*` is REPLACED, not appended. Calling `mind/reify!` twice in one turn results in only the second value.
- **I-MIND-2:** `*mind/pins*` length never exceeds `*mind/max-pins*`. Insertion evicts the oldest entry.
- **I-MIND-3:** `mind/note!` never calls `smart_ingest` more than 3 times per turn.
- **I-MIND-4:** `mind/note!` requires evidence. Empty evidence is rejected.
- **I-MIND-5:** `mind/reify!` deduplicates against `*mind/pins*` — overlapping content is not duplicated.
- **I-MIND-6:** All `*mind/*` variables are initialized before first use. No nil dereferences.
- **I-MIND-7:** Mind state survives process restart via prelude save/load (Phase 6).

---

## 3. Vestige Adapter Interface

### 3.1 TypeScript Interface

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
  // Recall — search for relevant memories
  recall(query: string, k: number, maxChars: number): Promise<RecallHit[]>;
  
  // Ingest — store a new memory
  ingest(entry: {
    content: string;
    tags?: string[];
    evidence?: string;
  }): Promise<boolean>;
  
  // Version — detect Vestige API version
  version(): Promise<string>;
  
  // Health check
  isHealthy(): Promise<boolean>;
}
```

### 3.2 Invariants

- **I-VESTIGE-1:** `recall` returns at most `k` results. Each excerpt is at most `maxChars` characters.
- **I-VESTIGE-2:** `recall` never throws. On failure, returns empty array and logs warning.
- **I-VESTIGE-3:** `ingest` returns false if rate limited or Vestige is down. Never throws.
- **I-VESTIGE-4:** The adapter isolates Pi-Lisptc from Vestige tool name changes. Version detection maps old → new names.
- **I-VESTIGE-5:** `recall` results below quality threshold (score < 0.1) are filtered before returning.

---

## 4. Prompt Layer Interface

### 4.1 Layer 0: Stable System Prompt

```typescript
function buildStablePrompt(): string {
  return [
    piCodingCore,      // Pi role, guidelines, concise/path rules
    lisptcChannel,      // Lisp-only output, halt/reply, MCP-in-image, mind rules
    interpreterSourceLlm // Language semantics (optimized subset)
  ].join('\n\n');
}
```

**Invariant:** This string changes only when: (a) the user switches workspace, (b) lisptc is upgraded, (c) Pi-Lisptc is upgraded. It does NOT change per-turn.

### 4.2 Layer 2: Volatile Mind State

```typescript
function buildVolatileMindState(
  retrieved: RecallHit[],
  pins: Pin[],
  prefs: UserPrefs,
  contributions: ContextContribution[]
): string {
  // Render mind_active summary
  // Render context contributions
  // Return as trailing developer message content
}
```

**Invariant:** This string changes every turn. It is NEVER concatenated into the system prompt.

---

## 5. Validation Pipeline Interface

### 5.1 Pipeline

```typescript
interface ValidationResult {
  ok: boolean;
  error?: string;      // Human-readable error for the model
  ast?: LispAST;        // Parsed AST (if ok)
}

function validateAndPrepare(rawText: string): ValidationResult {
  // 1. Exclude thinking parts
  // 2. Strip markdown fences
  // 3. Parse (reader)
  // 4. Return AST or error
}
```

### 5.2 Invariants

- **I-VALIDATE-1:** On validation failure, the form is NEVER passed to eval. Not even partially.
- **I-VALIDATE-2:** Error feedback to the model includes the specific parse error location.
- **I-VALIDATE-3:** Retry count is per-message, not per-session. Reset on new user message.
- **I-VALIDATE-4:** After max retries, the model receives a clear error and the user sees a notification.

---

## 6. Provider Mode Interface

### 6.1 Mode Selection

```typescript
type ProviderMode = 'grammar' | 'tool-call' | 'retry';

function selectProviderMode(
  provider: string,
  capabilities: ProviderCapabilities
): ProviderMode {
  if (capabilities.grammar) return 'grammar';
  if (capabilities.toolCalling) return 'tool-call';
  return 'retry';
}
```

### 6.2 Mode Behavior

| Mode | Mechanism | Fallback |
|------|-----------|----------|
| `grammar` | `response_format: { type: "grammar", grammar: LISP_GRAMMAR }` | Host validates defense-in-depth |
| `tool-call` | Single tool `eval_lisp_form({ form: string })`, forced `tool_choice` | Host validates extracted form |
| `retry` | No constraint, free text output | Host validates + retries |

### 6.3 Invariants

- **I-PROVIDER-1:** All modes end with host validation before eval. Grammar mode is not a substitute for validation.
- **I-PROVIDER-2:** `tool-call` mode extracts the `form` string from the tool call argument. It does NOT eval the raw tool call.
- **I-PROVIDER-3:** Mode selection is deterministic per provider. No runtime fallback between modes within a single request.
- **I-PROVIDER-4:** Cache fields (`prompt_cache_key`, `cache_control`) are preserved regardless of mode.

---

## 7. Context Contribution Interface (Phase 9)

### 7.1 Schema

```typescript
interface ContextContribution {
  id: string;
  instruction: string;       // max 4000 chars
  evidence?: string;         // max 2000 chars
  priority: number;          // higher = more important
  lifetime: 'turn' | 'next-request';
  cls: 'mandatory' | 'advice';
  deduplicationKey?: string;
  supersedes?: string[];     // contribution IDs
  conflictGroup?: string;
}
```

### 7.2 Budget

- Mandatory total: 8,000 characters hard cap
- Advisory total: ~2,000 tokens (~8,000 chars)

### 7.3 Invariants

- **I-CONTEXT-1:** Mandatory contributions are always included, subject to the 8k character hard cap.
- **I-CONTEXT-2:** Advisory contributions are sorted by priority. Budget overflow drops lowest-priority items.
- **I-CONTEXT-3:** Contributions with `lifetime: 'turn'` are consumed after rendering. They do not persist.
- **I-CONTEXT-4:** Contributions with `lifetime: 'next-request'` persist to the next turn, then are consumed.
- **I-CONTEXT-5:** The resolution pipeline is idempotent — running it twice with the same inputs produces the same output.
- **I-CONTEXT-6:** Contributor failures are isolated. One failing contributor does not prevent others from running.
- **I-CONTEXT-7:** The rendered text is delivered as a trailing developer message, not in the system prompt.