# Background: coherence and the living mind

## The coherence problem

When an agent generates code across many files and turns:

- It may re-implement a trigger that already exists in one module.  
- It loses the “spirit” of the design: one source of truth vs N variants.  
- Static graphs and docs lag and do not capture executable intent.

Desired property: an **up-to-date operational model**—what triggers what, what depends on what—that the agent **uses** on every turn.

## Why graphs and wikis fail as the primary solution

They are shadows of the codebase: often stale, incomplete, and **optional** at inference time. Hoping the model “will inquire the right folders” is unrealistic for both humans and models at generation speed.

## What “in the mind” means here

Not weights fine-tuned every hour (optional future). Means:

1. **Executable state** — bindings and functions in a REPL image.  
2. **Forced channel** — actions expressed as programs (Lisp), eval’d by the host.  
3. **Reified memory** — durable recall written into working bindings before act.  
4. **Host gates** — invalid programs never land in the session image.

## Related systems (contrast)

| System | Mind substrate | Model wire format |
|--------|----------------|-------------------|
| **lisptc** | TS Lisp REPL | Lisp-only (policy + optional grammar) |
| **Autolith** | SBCL live image | Prose + tools; Lisp optional |
| **Prime Agent** | Persistent IPython | Single tool: ipython (RLM) |
| **Pi default** | None (transcript + tools) | Prose + multi-tool |

Pi-Lisptc: **Pi harness + lisptc cortex + Vestige cabinet**, with **merged** coding prompt.
