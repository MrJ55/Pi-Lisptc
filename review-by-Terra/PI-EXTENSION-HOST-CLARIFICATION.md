# Pi-Lisptc extension-host clarification

## Decision

The Pi-Lisptc extension host is primarily an expanded, Pi-specific evolution of Lisptc's existing `apps/pi` integration, not a separate daemon or an outer wrapper around Pi.

Upstream Lisptc has an `apps/pi` package with extension modules including `extension/lisp-repl.ts` and `extension/system-prompt.ts`. Pi-Lisptc should extend those modules and add Pi-specific siblings while keeping reusable interpreter/MCP machinery comparatively close to upstream.

## Concrete placement

```text
packages/interpreter/       # Lisp engine and reusable runtime; minimal, intentional diffs
  lisp.ts
  mcp.ts
  mcp-broker.ts
  mcp-oauth.ts
  jobs.ts
  secrets.ts

apps/pi/                    # Pi-Lisptc extension host
  extension/
    lisp-repl.ts            # persistent session lifecycle and controlled evaluation
    system-prompt.ts        # Pi invariant prompt/context merge
    profiles.ts             # pi-default and lisp-mind policy selection
    action-channel.ts       # forced Lisp action path
    context-assembly.ts     # Pi context + retrieved Vestige + budgets
    vestige.ts              # retrieval, gated ingest, reification orchestration
    provider-policy.ts      # grammar / strict-tool / validate-and-retry selection
    input-safety.ts         # image/input validation and optional sandbox path
    output-protocol.ts      # (reply ...) and (halt ...) handling
    audit.ts                # turn/effect/reification ledger
  prelude/
    mind-api.lisp           # Lisp-facing stable mind API
```

The exact filenames can evolve. The critical boundary is dependency direction: Pi extension -> stable interpreter/prelude interface -> Lisptc MCP/providers/jobs/secrets. The interpreter must not import Pi-specific prompt, Vestige, UX, or profile policy.

## G1: Pi coding ability

For `lisp-mind`, `system-prompt.ts` composes an asymmetric prompt:

```text
Pi invariant system prompt
+ Pi coding role and safety/runtime instructions
+ AGENTS.md instructions
+ cwd, repository, files, diagnostics, and path conventions
+ current task
+ lisp-mind action contract
+ bounded retrieved Vestige context or recall manifest
```

The Pi portion is foundational. The mind profile may add an action-language contract but may not replace Pi's coding identity, AGENTS.md, cwd, project instructions, or concise/path guidance.

## G2: forced action channel

In `lisp-mind`, the normal model action path is:

```text
model-generated validated Lisp
  -> apps/pi extension lisp-repl session evaluation
  -> mind-api.lisp capability call
  -> Lisptc MCP broker/OAuth/secrets/jobs
  -> MCP server/tool
  -> structured Lisp result
  -> (reply ...) or (halt ...)
  -> Pi host pretty-printer
```

This is not an external tool swarm. Pi remains the host and coding context; Lisp is the action language; Lisptc's existing MCP capability executes the tools.

Use three enforcement layers:

1. Generation: grammar-constrained Lisp where supported; otherwise strict structured output; otherwise parse/validate/retry.
2. Profile runtime policy: `lisp-mind` denies normal broad outer action dispatch except a minimal bootstrap/control allowlist and carefully approved direct extensions such as `opencode-go-cache`.
3. Evaluation: only the persistent Lisp session receives the capability bridge; each MCP call is schema-validated, profile-authorized, budgeted, and audited.

## Appropriate core diffs

Minimal interpreter diffs do not prohibit needed hostability hooks. Legitimate small changes include programmatic persistent-session lifecycle, trusted prelude loading, structured evaluator events/results, cancellation propagation, MCP invocation/audit hooks, and grammar export for a safe action subset. These are seams that should ideally remain generally useful and potentially upstreamable.

## Related review documents

- [Architecture review](ARCHITECTURE-REVIEW.md)
- [Execution roadmap](EXECUTION-ROADMAP.md)
- [Interfaces and invariants](INTERFACES-AND-INVARIANTS.md)
- [Vestige reification clarification](VESTIGE-REIFICATION-CLARIFICATION.md)
