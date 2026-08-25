# lisptc vs Autolith vs Prime vs plain Pi

## lisptc

- Dialect + interpreter; pi extension evaluates assistant **text** as Lisp.  
- `setActiveTools([])`; system prompt policy: Lisp machine, no tools.  
- MCP via `load-mcp` → tools as Lisp functions (`server/tool`).  
- Optional Fireworks GBNF on `before_provider_request`.  
- User may still type English; **assistant output** is Lisp.

## Autolith

- Live Common Lisp **agent OS**; multi-tool by default.  
- Memories: sexp-store; **memory-context** auto-contributes lexically related memories each turn.  
- RLM, recovery generations, `self.*` — powerful, heavy; not required for v1 Pi-Lisptc.  
- Inspiration for: turn-local related memory injection (port pattern, not full product).

## Prime Agent

- Pi-lineage host + **one** tool: persistent IPython; `await rlm(...)` subagents.  
- Continual Harness `/refine`.  
- Often high token use on independent harness benchmarks; strong on some vendor long-context/ARC setups.  
- Overlaps UX-wise with “REPL agent”; different engine (Python vs Lisp).

## Plain Pi

- Lean coding agent; lowest token class in some Composio comparisons.  
- Performance tied to default system prompt + tools + AGENTS.md + extensions.  
- Pi-Lisptc must **preserve** this DNA in merge mode.

## Decision for this project

Use **lisptc + Pi + Vestige**, not a full switch to Autolith or Prime. Port **ideas** (auto memory context, validate, recovery mindset) without porting entire platforms in **core** phases 0–8.

**Additive track (phases 9–12):** optional, documented adaptations of Autolith patterns — context contributors, bounded RLM Lisp ops, agendas/papercuts, soft snapshots. See `docs/07-autolith-adaptation.md` and ADRs 0007–0009. These must not rewrite core deployment.
