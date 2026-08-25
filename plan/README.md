# Implementation plan

Execute **core** phases **in order** (0–8). Each phase file contains:

- Goals and exit criteria  
- Background pointers into `docs/` and `adr/`  
- **Detailed task list** suitable for a smaller coding model  
- Verification steps  

## Core phase index (deploy path)

| File | Phase |
|------|--------|
| [phase-00-baseline-profiles.md](./phase-00-baseline-profiles.md) | 0 Baseline & profiles |
| [phase-01-prompt-assembly.md](./phase-01-prompt-assembly.md) | 1 Prompt assembly |
| [phase-02-image-safety.md](./phase-02-image-safety.md) | 2 Image safety |
| [phase-03-provider-widening.md](./phase-03-provider-widening.md) | 3 Provider widening |
| [phase-04-mcp-bootstrap.md](./phase-04-mcp-bootstrap.md) | 4 MCP bootstrap |
| [phase-05-user-channel.md](./phase-05-user-channel.md) | 5 User channel |
| [phase-06-persistence-mind.md](./phase-06-persistence-mind.md) | 6 Persistence |
| [phase-07-vestige-reify.md](./phase-07-vestige-reify.md) | 7 Vestige reify loop |
| [phase-08-optional-harden.md](./phase-08-optional-harden.md) | 8 Optional harden |

## Additive track — Autolith feature adaptation (after 0–8)

These phases **follow** the core path. They must **not** be merged into phases 0–8 and must not change core deployment steps. See `docs/07-autolith-adaptation.md` and ADRs 0007–0009.

| File | Phase |
|------|--------|
| [phase-09-context-contributors.md](./phase-09-context-contributors.md) | 9 Context contributors |
| [phase-10-bounded-rlm.md](./phase-10-bounded-rlm.md) | 10 Bounded RLM Lisp ops |
| [phase-11-agenda-papercuts.md](./phase-11-agenda-papercuts.md) | 11 Agendas & papercuts |
| [phase-12-soft-generations.md](./phase-12-soft-generations.md) | 12 Soft generations |

## Rules for implementers

1. Read the phase’s **Background** links before coding.  
2. Complete tasks in listed order unless marked parallel.  
3. Do not skip verification.  
4. Do not implement phase N+1 features in phase N.  
5. Prefer small commits per task group.  
6. **Core first:** do not start phases 9–12 until 0–7 are usable daily (phase 8 optional).  
7. Additive track may ship partially; document subsets in `VERIFY-LOG.md`.
