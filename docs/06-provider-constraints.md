# Providers, grammar, and cache

## Fireworks grammar

Server-side constrained decoding: GBNF → mask invalid tokens at sample time. Requires logit access on the **serving** side (Fireworks hosts models). Client still should **validate** before eval.

## Providers without grammar

OpenCode Go, many gateways: soft prompt + **host validate + retry**. Optional strict JSON tool wrapping a single `form` string.

## Constraint adapter (target)

```text
before_provider_request:
  1. opencode-go-cache (or equivalent) — TTL, prompt_cache_key, cache_control
  2. if mode=grammar and provider supports: response_format grammar
  3. else if mode=json-tool: tool schema only
  4. else: no response_format (retry path)
```

## lisptc stock behavior to change

Do not unconditionally set Fireworks grammar on **every** provider payload.

## Cost note

Full interpreter source in the system prompt is large; rely on **prompt cache** and large context windows initially; split L0/L1 later (phase 8).
