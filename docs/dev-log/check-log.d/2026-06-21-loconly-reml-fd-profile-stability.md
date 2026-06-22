# 2026-06-21 — Location-only Gaussian REML finite-difference and local-profile stability

Goal:

- Continue the exact-Gaussian away-run slices by hardening finite-difference
  stability, local profile sanity, optimizer accounting, and PEV summaries.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-fd-profile-stability.md docs/dev-log/after-task/2026-06-21-loconly-reml-fd-profile-stability.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added finite-difference gradient/Hessian stability diagnostics across multiple
  step sizes.
- Added local profile sanity diagnostics for residual and phylogenetic log-SD
  axes.
- Extended the optimizer diagnostic with local-profile evidence, FD-stability
  evidence, start counts, finite-record counts, accepted-record counts, and best
  start-to-optimum improvement.
- Extended PEV diagnostics with min/max, leaf mean, and weighted leaf trace
  summaries.
- The focused test passed: 137/137 assertions in 7.1 seconds.

Boundary:

- The optimizer remains a finite-difference experiment with
  `ai_reml_ready = false`. These are diagnostic hardening slices only: no public
  API, no bridge promotion, no q4/non-Gaussian/Ayumi/10k claim.
