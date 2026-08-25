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

### T8.5 — RLM / Autolith-scale features

1. Only if measured need for million-token context decomposition.

## Exit criteria

Each sub-item optional; document what shipped.
