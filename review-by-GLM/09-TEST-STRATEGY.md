# Review-by-GLM5p3 — Test Strategy

Recommended testing approach for Pi-Lisptc.

---

## 1. Test Framework

**Vitest** — consistent with lisptc's existing test infrastructure. lisptc uses Vitest for all packages (`vitest.config.ts` in interpreter, repl, lsp). Pi-Lisptc should follow suit.

```json
// package.json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  }
}
```

---

## 2. Test Layers

### 2.1 Unit Tests

Test individual functions in isolation.

**Phase 1 — Prompt Assembly:**
- `buildStablePrompt()` returns non-empty string
- Prompt contains Pi coding core markers
- Prompt contains lisptc channel markers
- Prompt contains interpreter source (search for `defun evalTopLevel`)
- Prompt does NOT contain volatile mind state
- `INTERPRETER_SOURCE_LLM` does NOT include `mcp-broker.ts` content
- Token count of stable prompt is logged and within budget

**Phase 2 — Validation:**
- `stripFences()` removes ```lisp fences, bare backticks, and handles nested fences
- `stripFences()` preserves code without fences
- `validateForm()` accepts valid lisptc: `(+ 1 2)`, `(defun foo (x) x)`, `(load-mcp "vestige")`
- `validateForm()` rejects invalid: `"Hello"` (not a form), `(+ 1`, `(defun)`, unbalanced parens
- `validateForm()` rejects prose: "I'll help you with that"
- Retry counter increments on validation failure
- Retry counter resets on new user message
- After max retries, error is reported to user

**Phase 6 — Mind API:**
- `mind/reify!` replaces `*mind/retrieved*` (call twice, only second value persists)
- `mind/reify!` with `:merge-prefs t` updates `*mind/user*`
- `*mind/pins*` evicts oldest when exceeding max
- `mind/note!` with empty evidence is rejected
- `mind/note!` rate limit enforced (4th call in one turn rejected)
- `mind/skip!` does not call smart_ingest

### 2.2 Integration Tests

Test multiple components working together.

**Phase 0-1 — Extension Loading:**
- Pi loads pi-lisptc extension without error
- `pi-default` profile: tools are NOT cleared, system prompt is NOT modified
- `lisp-mind` profile: tools ARE cleared, system prompt IS merged
- Both profiles can be launched via their respective scripts
- `opencode-go-cache` and `pi-lisptc` coexist without conflicts

**Phase 2-3 — Validation + Provider:**
- Grammar mode: model output passes validation, evals successfully
- Tool-call mode: tool call extracted, form validated, evals successfully
- Retry mode: invalid output rejected, retry produces valid output
- Provider switch: same session works on different providers

**Phase 7 — Vestige Reify Loop:**
- Vestige recall returns results → reify! called → mind_active injected
- Vestige down → empty recall → mind_active is minimal → agent continues
- Vestige returns garbage (low scores) → quality threshold filters → empty recall
- Ingest succeeds → smart_ingest called → Vestige stores the memory
- Ingest fails → queue → retried next turn
- Rate limit: 4th note! in one turn rejected

### 2.3 Contract Tests

Test that Pi-Lisptc's assumptions about upstream APIs hold.

**Pi Contract:**
- `buildSystemPrompt({ customPrompt })` still appends project context
- `setActiveTools([])` clears all tools
- `before_provider_request` modifications are composable

**lisptc Contract:**
- `AgentRepl.eval(code)` returns output string
- `AgentRepl.reset()` clears all definitions
- `AgentRepl.takeHalted()` returns true after `(halt)`
- `setConversationVars()` updates conversation globals before eval
- `INTERPRETER_SOURCE` contains `evalTopLevel` and `defun eval` (verify it's the full language)

**Vestige Contract:**
- `list-tools` returns recall and smart_ingest (or current version's equivalents)
- `recall` accepts query string, returns array of hits
- `smart_ingest` accepts content, stores durably

### 2.4 End-to-End Tests

Test complete user scenarios.

**Scenario 1: Basic coding session (5 turns)**
1. User: "Read src/index.ts and explain it"
2. Agent: Loads file via MCP, replies with explanation
3. User: "Add error handling to the main function"
4. Agent: Reads file, edits it, confirms
5. Verify: File modified, mind has note about the change

**Scenario 2: Mind persistence (3 turns, restart)**
1. User: "Remember: this project uses pnpm, not npm"
2. Agent: `mind/note!` → Vestige
3. Restart Pi
4. User: "What package manager do we use?"
5. Agent: Recalls from Vestige, answers "pnpm"

**Scenario 3: Error recovery (definition survives)**
1. Agent: `(defun analyze (x) (+ x 1))` — success
2. Agent: `(analyze "not a number")` — type error
3. Verify: `analyze` still exists in REPL
4. Agent: `(analyze 5)` — returns 6

**Scenario 4: Profile switch**
1. Start in `lisp-mind`
2. Agent does work
3. Exit, start in `pi-default`
4. Verify: Normal Pi tools available, no Lisp channel

---

## 3. Test Data Fixtures

### Vestige Mock

```typescript
// test/fixtures/mock-vestige.ts
export class MockVestigeAdapter implements VestigeAdapter {
  private memories: Map<string, RecallHit> = new Map();
  
  async recall(query: string, k: number): Promise<RecallHit[]> {
    // Simple substring matching for testing
    return Array.from(this.memories.values())
      .filter(m => m.title.includes(query) || m.excerpt.includes(query))
      .slice(0, k);
  }
  
  async ingest(entry: { content: string; tags?: string[] }): Promise<boolean> {
    const id = `mock-${Date.now()}`;
    this.memories.set(id, {
      id, title: entry.content.slice(0, 50),
      excerpt: entry.content.slice(0, 180),
      score: 1.0, tags: entry.tags || [],
      updatedAt: new Date().toISOString()
    });
    return true;
  }
  
  async version(): Promise<string> { return 'mock'; }
  async isHealthy(): Promise<boolean> { return true; }
  
  // Test controls
  setHealthy(healthy: boolean) { this._healthy = healthy; }
  setRecallError(error: boolean) { this._recallError = error; }
}
```

### Provider Mock

```typescript
// test/fixtures/mock-provider.ts
export class MockProvider {
  constructor(private responses: string[]) {}
  
  async complete(request: any): Promise<{ content: string }> {
    const response = this.responses.shift() || '';
    return { content: response };
  }
  
  setResponses(responses: string[]) {
    this.responses = responses;
  }
}
```

---

## 4. CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: pnpm install
      - run: pnpm typecheck
      - run: pnpm test
  contract:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: pnpm install
      - run: pnpm test -- --grep "contract"
```

---

## 5. Coverage Targets

| Component | Target Coverage | Rationale |
-----------|----------------|-----------|
| Prompt assembly | 90% | Critical — wrong prompt = broken agent |
| Validation pipeline | 95% | Security — prevents eval of unvalidated code |
| Mind API (Lisp) | 80% | Core functionality |
| Vestige adapter | 80% | External dependency, failure modes important |
| Provider modes | 70% | Multiple code paths, hard to test all providers |
| Extension hooks | 60% | Depends on Pi API, hard to mock |

---

## 6. Testing Principles

1. **Test the invariants, not the implementation.** The interfaces document (08-INTERFACES-AND-INVARIANTS.md) defines I-PI-1 through I-CONTEXT-7. Each invariant should have at least one test.

2. **Test failure modes, not just success paths.** The error recovery tests (Scenario 3) are more important than the happy-path tests.

3. **Mock at boundaries.** Mock Vestige (external MCP), mock providers (external HTTP), but do NOT mock the lisptc interpreter. Test against the real interpreter.

4. **Contract tests protect against upstream changes.** When lisptc or Pi releases a new version, contract tests fail first, giving early warning.

5. **No tests for other review folders.** This review is independent. No tests read or depend on review-by-Luna, review-by-Sonnet, etc.