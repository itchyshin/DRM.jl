# Generic profile nuisance-status evidence

## Retained behavioral red

`red-002.log` is the pre-implementation behavioral red: 5 passed, 2 failed,
and 4 errored in 6.9 s.  It records that generic profiling lacked a
status-bearing nuisance result, propagated a nuisance exception from an
endpoint, and plotting silently clamped a materially negative likelihood-ratio
value.

## Historical finite/non-converged probe

`probe_original_nonconverged.jl` replayed the pre-slice stored-gradient branch
of `_profile_optimize` from `HEAD` (source SHA
`cc7befa0aa8d27888c3f317c3ae22448e712672cbddd5fe675dc7a0c9b94765d`)
against a deterministic chained Rosenbrock nuisance objective.  The retained
`original-nonconverged-002.log` reports exactly 40 iterations,
`converged=false`, a finite minimizer, and finite minimum `0.8034616192008257`.
The old helper would have returned that pair without an acceptance status.

`original-nonconverged-001.log` is retained as a syntax-only probe setup
failure; it made no model fit or numerical claim.

## Current focused check

`green-009.log` ran the final standalone analytic test with one Julia thread
and one BLAS thread: 70 assertions passed in 7.2 s (14 s wall-clock including
local compilation). It checks successful and rejected nuisance solves, direct
no-nuisance evaluation, finite/non-finite/interrupt paths, explicit fallback
status, endpoint and warning behavior, reference integrity at ordinary and
large additive NLL shifts, overflow, an evaluated-coordinate collapse path,
and both plot-data providers.

`green-threaded-003.log` repeated the final test with two Julia threads and
one BLAS thread: 74 assertions passed in 7.5 s. The extra assertions exercise
the single-coefficient parallel endpoint-arm status path.

This evidence verifies Optim termination plus finite minimizer and re-evaluated
objective. It does not add a score/stationarity gate, prove a globally first
crossing on a non-monotone profile, or exercise the separate location-only and
location-scale profile solvers.

## Integrated verification

Final combined002 passes212 assertions, including13 independent endpoint/oracle
checks and10 selected-row bridge checks, plus existing profile/plot/target
neighbours. The100-file manifest is unchanged. docs001 executes19 examples on
three guide pages (29.953buildseconds); this does not qualify a full visual build
or deployed pages. Exact source and commands are retained in the JSON receipts.

The drmTMB twin retains public004 under the same evidence directory name:
ordinary Rscript actual GaussianML profile plus15 injected transport cases
PASS in20.899seconds, all141before/after/current source hashes match. Checker003
rejects12 deliberately damaged receipts, including omittedcriticalsource, absent
bounds/coefficients/loglik, false loadedpath and generatedwrapperhash. Injected
cases test transport only; they do not reproduce numerical optimizer failures.

Earlier combined001 is superseded after independent review caught optimizer-
default and tolerance regressions; combined001-review.md explains that history.
R public001 stopped at depot lock before fitting; public003 completed but its
checker failed AST extraction. No failed or superseded evidence was discarded.
