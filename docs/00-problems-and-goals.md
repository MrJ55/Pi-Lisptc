# Problems and goals

## Problems

### P1 — Coherence failure under generation speed

Models lose track of how generated modules connect: duplicated triggers/gates, variant implementations of one concept, forgotten invariants. Human review cannot scale to the rate of AI code generation.

### P2 — Filing-cabinet knowledge

Graphs, wikis, skills, and memory tools are **optional**. Models often ignore them unless reminded or forced. Knowledge “in folders” is not knowledge “in the mind.”

### P3 — Context and schema bloat

Multiple Pi extensions and MCP schemas (on the order of tens of thousands of tokens) compete for context without producing a single coherent operational state.

### P4 — Stock lisptc vs Pi coding performance

Upstream lisptc pi extension **replaces** the system prompt with a Lisp-machine policy and sets **active tools to []**. Pi’s default prompt encodes the coding-agent role, tool list, guidelines (concise, show paths), project context, and skills—much of what coding performance depends on. A pure replace optimizes format, not Pi coding ability.

### P5 — Provider and safety gap

Fireworks grammar can force Lisp syntax. Many providers (e.g. OpenCode Go) cannot. Malformed output must not corrupt the REPL image. Cache optimizations (`opencode-go-cache`) must coexist with constraints.

### P6 — Memory without reification

Even strong memory servers (Vestige) only help if recall is **loaded into working state**. Tool results the model may ignore are still a filing cabinet.

## Goals

| ID | Goal | Measurable outcome |
|----|------|--------------------|
| G1 | Preserve Pi coding DNA | Merged prompt includes Pi role + AGENTS/cwd; coding tasks still work |
| G2 | Programmatic channel | lisp-mind: outer tools empty or minimal; MCP via in-image calls |
| G3 | Working cortex | REPL holds `*mind/*`, skills; survives turns in-process |
| G4 | Durable cabinet | Vestige stores long-term; hybrid/keyword recall |
| G5 | Forced relevance | Host auto-recall + reify each user turn; top-k budget |
| G6 | Safe eval | No session eval on parse failure; retry budget |
| G7 | Multi-provider | At least one grammar path + one retry path documented and tested |
| G8 | UX | User sees `reply`/`halt` or pretty-printed data, not raw dialect only |
| G9 | Controlled evolution | Epilogue ingest gated; retrieved set **replaced** each turn; pins capped |
| G10 | Profiles | `pi-default` unchanged for classic work; `lisp-mind` for mind mode |

## Design principles

1. **Enhance Pi, do not eliminate it.**  
2. **Host enforces** read/reify/validate; prompts guide.  
3. **Cabinet ≠ cortex** — Vestige durable; image live; reify bridges them.  
4. **Replace turn retrieval; cap durable pins.**  
5. **Cache and constraints compose** (cache first on the wire).  
6. **Expedient then optimize** — full interpreter source in prompt OK initially if cache hits.
