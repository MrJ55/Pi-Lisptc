# Interfaces and Invariants (Gemini)

## Host/interpreter boundary

**Invariant:** Pi extension (`apps/pi/extension`) → stable interpreter/prelude interface → Lisptc MCP/providers/jobs/secrets (`packages/interpreter`).

**Dependency direction:** Pi extension depends on interpreter; interpreter must not import Pi-specific prompt, Vestige, UX, or profile policy.

### Interpreter interface (stable)

```ts
// packages/interpreter/src/lisp.ts
export interface LispSession {
  eval(code: string): Promise<LispResult>;
  loadPrelude(path: string): Promise<void>;
  saveSession(path: string): Promise<void>;
  on(event: 'eval' | 'result' | 'error', handler: (data: any) => void): void;
}

// packages/interpreter/src/mcp.ts
export interface MCPBroker {
  callTool(server: string, tool: string, args: Record<string, any>): Promise<any>;
  listServers(): Promise<ServerInfo[]>;
}

// packages/interpreter/src/secrets.ts
export interface SecretsStore {
  get(key: string): Promise<string | undefined>;
  set(key: string, value: string): Promise<void>;
}
```

### Pi extension interface (host-specific)

```ts
// apps/pi/extension/lisp-repl.ts
export interface LispRepl {
  startSession(): Promise<LispSession>;
  evalInSession(session: LispSession, code: string): Promise<LispResult>;
  loadPrelude(session: LispSession, path: string): Promise<void>;
}

// apps/pi/extension/system-prompt.ts
export interface SystemPromptBuilder {
  buildPrompt(profile: 'pi-default' | 'lisp-mind', context: PiContext): Promise<SystemPrompt>;
}

// apps/pi/extension/vestige.ts
export interface VestigeOrchestrator {
  recall(query: RecallQuery): Promise<RecallResult[]>;
  ingest(event: VestigeEvent): Promise<void>;
  reify(session: LispSession, results: RecallResult[]): Promise<void>;
}
```

---

## Prelude contract

**Invariant:** Prelude is trusted, minimal, and stable. Host loads prelude at session start; model never sees prelude source.

### Mind API (prelude)

```lisp
;; mind-api.lisp (trusted prelude)

;; Turn recall (replace-not-accumulate)
(defun mind.replace-turn-recall (data) ...)
(defun mind.recall-all () ...)
(defun mind.recall-by-tag (tag) ...)
(defun mind.recall-by-kind (kind) ...)
(defun mind.recall-get (id) ...)
(defun mind.recall-search (query) ...)

;; Agendas (optional, phase 11)
(defun mind.agenda-get () ...)
(defun mind.agenda-update (entry) ...)

;; Papercuts (optional, phase 11)
(defun mind.papercut! (defect) ...)
(defun mind.papercut-list () ...)
(defun mind.papercut-close (id) ...)

;; Snapshots (optional, phase 12)
(defun mind.snapshot! (&key label) ...)
(defun mind.restore (&key label) ...)
```

**Invariant:** Prelude functions are allowlisted for eval. Never evaluate raw text fields from memory or model output.

---

## Reification contract

**Invariant:** Vestige content must never become arbitrary executable Lisp. Host constructs data-only literal passed to trusted prelude function.

### Safe reification form

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

**Validation pipeline:**
```
Vestige record
  -> schema validation
  -> scope/sensitivity filtering
  -> relevance ranking and item/token budget
  -> data-only Lisp serializer
  -> parse to Lisp AST
  -> allowlist validation: only (mind.replace-turn-recall <quoted-literal>)
  -> evaluate in active session
```

---

## Profile policy

**Invariant:** `lisp-mind` profile denies broad outer action dispatch except minimal bootstrap/control allowlist.

### Minimal bootstrap allowlist

```ts
// apps/pi/extension/action-channel.ts
const LISP_MIND_ALLOWLIST = [
  'opencode-go-cache', // approved direct extension
  // ... other minimal bootstrap/control tools
];

export function isAllowedInLispMind(tool: string): boolean {
  return LISP_MIND_ALLOWLIST.includes(tool);
}
```

**Invariant:** MCP calls from Lisp actions are schema-validated, profile-authorized, budgeted, audited.

---

## Audit manifest

**Invariant:** Every turn records audit manifest for diagnostics and reproducibility.

### Audit record schema

```ts
interface TurnAudit {
  turnId: string;
  timestamp: number;
  profile: 'pi-default' | 'lisp-mind';
  provider: string;
  mode: 'grammar' | 'strict-tool' | 'validate-retry';
  recallQuery?: RecallQuery;
  recallResults: RecallResult[];
  reificationForm: string; // validated Lisp form
  evalResult: LispResult;
  mcpCalls: MCPCallRecord[];
  smartIngestCandidates: VestigeEvent[];
  smartIngestDecision: 'ingest' | 'skip';
  smartIngestReason?: string;
}
```

**Invariant:** Audit manifest is logged to disk (optional) and available for host diagnostics.

---

## Invariants summary

| Invariant | Rationale | Enforcement |
|-----------|-----------|-------------|
| Interpreter must not import Pi-specific prompt/Vestige/UX | Reusability; clean boundaries | Code review; lint rule |
| Prelude is trusted, minimal, stable | Security; predictability | Host loads prelude; model never sees source |
| Never evaluate raw text fields | Safety; no arbitrary code exec | Validation pipeline; allowlist |
| `lisp-mind` denies broad outer tools | Forced action channel | Profile policy; minimal allowlist |
| MCP calls are schema-validated, authorized, budgeted, audited | Security; observability | Audit manifest; logging |
| Replace-not-accumulate for turn recall | No memory bloat | Host enforces; prelude API |
| Audit manifest per turn | Diagnostics; reproducibility | Logging; disk storage |

---

## Related documents

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Execution roadmap](EXECUTION-ROADMAP.md)
- [Test strategy](TEST-STRATEGY.md)
- [ADR recommendations](ADR-RECOMMENDATIONS.md)
