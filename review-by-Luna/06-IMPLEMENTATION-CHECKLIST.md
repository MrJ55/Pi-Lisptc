# Implementation Checklist

## Foundation

- [ ] Pin upstream lisptc revision.
- [ ] Capture interpreter behavior in automated tests.
- [ ] Establish fork divergence ledger.
- [ ] Define supported Node/Bun/runtime matrix.

## Host contract

- [ ] Define request/response schemas.
- [ ] Add correlation IDs.
- [ ] Add capability discovery.
- [ ] Add cancellation propagation.
- [ ] Add deadlines and resource budgets.
- [ ] Add structured lifecycle events.

## Evaluation safety

- [ ] Parse/validate before execution.
- [ ] Enforce capability policy before external effects.
- [ ] Define memory/time/output limits.
- [ ] Add failure-injection tests.
- [ ] Define commit/rollback behavior.

## Pi integration

- [ ] Use Pi as model/provider authority.
- [ ] Remove provider-specific assumptions from fork-specific code where practical.
- [ ] Verify dynamic model/provider visibility.
- [ ] Verify session lifecycle and shutdown.

## Jobs/MCP

- [ ] Reuse upstream jobs/MCP primitives.
- [ ] Add cancellation.
- [ ] Add quotas.
- [ ] Add timeout handling.
- [ ] Add observability.
- [ ] Test concurrent jobs and failures.

## State and memory

- [ ] Define working-state schema.
- [ ] Define snapshot schema/version.
- [ ] Test restore compatibility.
- [ ] Keep durable memory external to interpreter state.
- [ ] Implement bounded context contributors.

## RLM

- [ ] Child capability reduction.
- [ ] Recursion depth limit.
- [ ] Child-count limit.
- [ ] Wall-clock deadline.
- [ ] Token/output budget.
- [ ] Cancellation propagation.
- [ ] Child-state isolation/transactionality.
- [ ] Adversarial recursion tests.

## Release gates

- [ ] No capability bypass.
- [ ] No unbounded recursion.
- [ ] No uncontrolled external side effects.
- [ ] Deterministic state behavior after failures.
- [ ] Reproducible test suite.
- [ ] Documented upstream divergence.
