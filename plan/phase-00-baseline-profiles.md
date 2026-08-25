# Phase 0 — Baseline and profiles

## Goal

Establish two launch paths without changing lisptc core behavior yet: **pi-default** (classic Pi) and **lisp-mind** (placeholder for this extension).

## Background

- `docs/00-problems-and-goals.md`  
- `adr/0006-profiles-lisp-mind-vs-pi-default.md`  
- Upstream: earendil-works/pi extension loading (`-e`, settings)  
- Upstream: 1hachem/lisptc `apps/pi/extension/lisp-repl.ts`

## Exit criteria

- [ ] Documented commands to start each profile  
- [ ] `pi-default` runs without lisptc; tools work  
- [ ] `lisp-mind` loads this repo’s extension (even if still forked stock behavior)  
- [ ] `opencode-go-cache` (or stub) listed as compatible companion extension  

---

## Detailed tasks

### T0.1 — Clone upstream references (read-only)

1. Clone or submodule-note: `earendil-works/pi`, `1hachem/lisptc`.  
2. Record commit SHAs in `docs/UPSTREAM-PINS.md` (create file).  
3. Do not vendor entire trees yet unless needed.

### T0.2 — Scaffold extension package

1. Under `src/extension/`, create package.json compatible with Pi extension loading (follow lisptc `apps/pi/package.json` pattern).  
2. Entry: `index.ts` or `lisp-repl.ts` exporting `default function (pi: ExtensionAPI)`.  
3. For this phase only: minimal extension that `console`/notifies “pi-lisptc loaded” on `session_start`.

### T0.3 — Scripts

1. Create `scripts/run-pi-default.sh`: launches pi **without** pi-lisptc; with cache extension if present.  
2. Create `scripts/run-lisp-mind.sh`: launches pi **with** `-e` path to this extension + cache.  
3. Document env vars: `FIREWORKS_API_KEY`, etc.

### T0.4 — README profile section

1. Ensure root README profiles match scripts.  
2. State clearly: phase 0 does not yet merge prompts.

### T0.5 — Verification

1. Run pi-default; ask model to `ls` or read a file (default tools).  
2. Run lisp-mind; confirm notify “pi-lisptc loaded”.  
3. Record results in `plan/VERIFY-LOG.md`.

## Out of scope

Prompt merge, Vestige, validate-before-eval.
