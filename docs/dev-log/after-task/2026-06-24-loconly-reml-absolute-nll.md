# After Task: Location-Only REML Absolute NLL Review Correction

## Task

Review DRM.jl PR #297 and correct any narrow issues before treating it as ready
for maintainer review.

## What Changed

The location-only exact-Gaussian REML helper now subtracts the fixed-effect
constant offset `0.5 * k * log(2π)` from the profiled ML objective plus
`0.5 * logdet(X'V^{-1}X)`. This keeps the optimizer, score, Hessian, and
simulation diagnostics unchanged, but makes `reml_nll` the conventional
restricted negative log-likelihood value expected by future external comparator
fixtures.

The focused test now recomputes the dense GLS REML reference with that same
constant and separately checks the restricted fixed-effect log-determinant
penalty.

## Files

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-24-loconly-reml-absolute-nll.md`
- `docs/dev-log/after-task/2026-06-24-loconly-reml-absolute-nll.md`

## Validation

Validation rerun after this patch:

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. test/test_bridge.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|q4 interval reliability|q4 interval coverage|coverage accepted|public support|R bridge promotion|Ayumi reply|ai_reml_ready = true|ai_reml_ready=true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-24-loconly-reml-absolute-nll.md docs/dev-log/after-task/2026-06-24-loconly-reml-absolute-nll.md
```

Result: `test/test_location_only_reml_mme.jl` passed 602/602 assertions.
`test/test_bridge.jl` passed 46/46 assertions. `git diff --check` was clean.
The overclaim scan returned only this report's own guardrail command/boundary
text and did not find a promoted support claim in the changed source or tests.

## Claim Boundary

This remains exact-Gaussian location-only developer evidence. It is not q4
evidence, not non-Gaussian evidence, not R bridge promotion, not interval
coverage evidence, and not AI-REML readiness.

## Follow-Up

Future external comparator work should compare the conventional restricted
likelihood value, variance-component point estimates, covariance target, and
boundary labels on a genuinely same-estimand fixture.
