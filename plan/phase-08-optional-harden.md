# Phase 8 — Optional hardening (later)

## Goal

Optimize and harden after phases 0–7 work daily.

## Tasks (priority order)

### T8.1 — Prompt L0/L1

1. L0: channel + Pi core without full interpreter source.  
2. L1: load source on demand or first session only.  
3. Measure cache hit rates before/after.

### T8.2 — Sandbox eval

1. Eval in throwaway environment; commit defs to session only on success.  
2. Protect against lobotomy from bad defun.

### T8.3 — Shared constraint adapter package

1. Extract grammar|retry|json + cache ordering for reuse.

### T8.4 — Worker isolation

1. Optional subprocess for untrusted MCP side effects.

### T8.5 — Pointer to Autolith additive track

1. Do **not** implement RLM or full Autolith surfaces here.  
2. If measured need for long-context decomposition or richer turn-local context, proceed to **phases 9–12** (`docs/07-autolith-adaptation.md`).  
3. T8.1–T8.4 remain the only harden work inside this phase.

## Exit criteria

Each sub-item optional; document what shipped. RLM / contributors / agendas live in the additive track, not phase 8.
