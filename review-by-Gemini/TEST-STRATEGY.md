# Test Strategy (Gemini)

## Validation gates

### Gate 1: Image safety (phase 2)

**Test:** Malformed model output must not corrupt REPL state.

```ts
// apps/pi/extension/test/lisp-repl.test.ts
import { LispRepl } from '../lisp-repl';
import { LispSession } from '../../../packages/interpreter/src/lisp';

test('malformed Lisp does not corrupt session', async () => {
  const repl = new LispRepl();
  const session = await repl.startSession();
  
  // Malformed output (missing closing paren)
  const malformed = '(defun test () (+ 1 2';
  
  const result = await repl.evalInSession(session, malformed);
  
  expect(result.status).toBe('parse-error');
  expect(result.retryCount).toBeLessThanOrEqual(3);
  
  // Session should still be usable
  const validResult = await repl.evalInSession(session, '(+ 1 2)');
  expect(validResult.status).toBe('success');
  expect(validResult.value).toBe(3);
});
```

**Exit criteria:** No REPL corruption in 100+ turns with malformed eval.

---

### Gate 2: Reification safety (phase 7)

**Test:** Vestige recall must be reified as data-only literal, not arbitrary code.

```ts
// apps/pi/extension/test/vestige.test.ts
import { VestigeOrchestrator } from '../vestige';
import { LispSession } from '../../../packages/interpreter/src/lisp';

test('Vestige recall is reified as data-only literal', async () => {
  const vestige = new VestigeOrchestrator();
  const session = await repl.startSession();
  
  const recallResults = await vestige.recall({ query: 'pnpm workspaces', topK: 5 });
  
  // Reify should construct data-only literal
  const reificationForm = await vestige.reify(session, recallResults);
  
  expect(reificationForm).toMatch(/^\(mind\.replace-turn-recall\s+'\(/);
  expect(reificationForm).not.toMatch(/eval\(/); // No raw eval
  expect(reificationForm).not.toMatch(/record\.text/); // No direct text field eval
  
  // Session should still be usable
  const validResult = await repl.evalInSession(session, '(+ 1 2)');
  expect(validResult.status).toBe('success');
});
```

**Exit criteria:** No arbitrary code execution from Vestige recall in 100+ turns.

---

### Gate 3: Provider modes (phase 3)

**Test:** Provider mode selection works for Fireworks, OpenAI, Anthropic.

```ts
// apps/pi/extension/test/provider-policy.test.ts
import { ProviderPolicy } from '../provider-policy';

test('Fireworks uses grammar mode', () => {
  const policy = new ProviderPolicy();
  const mode = policy.selectMode('fireworks/llama-3.1-8b');
  expect(mode).toBe('grammar');
});

test('OpenAI uses validate-retry mode', () => {
  const policy = new ProviderPolicy();
  const mode = policy.selectMode('openai/gpt-4o');
  expect(mode).toBe('validate-retry');
});

test('Anthropic uses validate-retry mode', () => {
  const policy = new ProviderPolicy();
  const mode = policy.selectMode('anthropic/claude-3.5-sonnet');
  expect(mode).toBe('validate-retry');
});

test('Unknown provider defaults to validate-retry', () => {
  const policy = new ProviderPolicy();
  const mode = policy.selectMode('unknown/provider');
  expect(mode).toBe('validate-retry');
});
```

**Exit criteria:** Provider mode selection works without silent fallback failures.

---

### Gate 4: Replace-not-accumulate (phase 7)

**Test:** Turn recall is replaced, not accumulated.

```ts
// apps/pi/extension/test/vestige.test.ts
import { VestigeOrchestrator } from '../vestige';
import { LispSession } from '../../../packages/interpreter/src/lisp';

test('Turn recall is replaced, not accumulated', async () => {
  const vestige = new VestigeOrchestrator();
  const session = await repl.startSession();
  
  // Turn 1 recall
  const recall1 = await vestige.recall({ query: 'pnpm workspaces', topK: 3 });
  await vestige.reify(session, recall1);
  
  const recallState1 = await repl.evalInSession(session, '(mind.recall-all)');
  expect(recallState1.value.items).toHaveLength(3);
  
  // Turn 2 recall (should replace, not accumulate)
  const recall2 = await vestige.recall({ query: 'TypeScript config', topK: 2 });
  await vestige.reify(session, recall2);
  
  const recallState2 = await repl.evalInSession(session, '(mind.recall-all)');
  expect(recallState2.value.items).toHaveLength(2); // Replaced, not 5
  expect(recallState2.value.items.map(i => i.id)).toEqual(expect.not.arrayContaining(recall1.map(r => r.id)));
});
```

**Exit criteria:** Turn recall is replaced every turn; no memory bloat.

---

### Gate 5: Smart ingest gating (phase 7)

**Test:** `smart_ingest` gates writes to durable memory.

```ts
// apps/pi/extension/test/vestige.test.ts
import { VestigeOrchestrator } from '../vestige';

test('smart_ingest gates writes to durable memory', async () => {
  const vestige = new VestigeOrchestrator();
  
  // Candidate fact (duplicate of existing)
  const candidate1 = {
    kind: 'project-fact',
    text: 'The repository uses pnpm workspaces.',
    scope: 'workspace',
  };
  
  const decision1 = await vestige.smartIngest(candidate1);
  expect(decision1).toBe('skip');
  expect(decision1.reason).toMatch(/duplicate/);
  
  // Candidate fact (novel, high confidence)
  const candidate2 = {
    kind: 'project-fact',
    text: 'New fact about build system.',
    scope: 'workspace',
    confidence: 0.95,
  };
  
  const decision2 = await vestige.smartIngest(candidate2);
  expect(decision2).toBe('ingest');
});
```

**Exit criteria:** `smart_ingest` gates writes; no noise in durable memory.

---

## Integration tests

### Test: End-to-end `lisp-mind` workflow

```ts
// apps/pi/extension/test/e2e.test.ts
import { PiAgent } from '../pi-agent';

test('lisp-mind profile works end-to-end', async () => {
  const agent = new PiAgent({ profile: 'lisp-mind' });
  
  // User message
  const message = 'Add a new file to the workspace';
  
  // Agent should generate Lisp, eval, call MCP, return result
  const result = await agent.send(message);
  
  expect(result.status).toBe('success');
  expect(result.lispForm).toMatch(/^\(mind\./);
  expect(result.mcpCalls).toBeDefined();
  expect(result.reply).toBeDefined();
  
  // Audit manifest should be recorded
  expect(agent.auditManifest).toBeDefined();
  expect(agent.auditManifest.turns).toHaveLength(1);
});
```

**Exit criteria:** End-to-end `lisp-mind` workflow works for daily coding tasks.

---

## Test coverage goals

| Component | Coverage goal | Rationale |
|-----------|---------------|-----------|
| `lisp-repl.ts` | 90%+ | Core of forced action channel; image safety critical |
| `system-prompt.ts` | 80%+ | Prompt assembly; must merge correctly |
| `vestige.ts` | 85%+ | Reification safety; smart_ingest gating |
| `provider-policy.ts` | 95%+ | Provider mode selection; must not fail silently |
| `action-channel.ts` | 90%+ | Minimal allowlist; must deny broad outer tools |

---

## Related documents

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Execution roadmap](EXECUTION-ROADMAP.md)
- [Interfaces and invariants](INTERFACES-AND-INVARIANTS.md)
- [ADR recommendations](ADR-RECOMMENDATIONS.md)
