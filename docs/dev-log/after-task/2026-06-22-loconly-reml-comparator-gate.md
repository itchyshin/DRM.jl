# After Task: Location-Only Gaussian REML Comparator Gate

## Goal

Add a no-dependency comparator gate for the exact-Gaussian location-only REML
diagnostic lane, so future external-comparator work has a schema and target
guard before any package dependency or optional developer script is added.

## Implemented

`_loconly_reml_external_comparator_schema()` defines the planned comparator
artifact fields. `_loconly_reml_external_comparator_status()` returns a
row-shaped status table with `external_comparator_status = :planned`,
`dependency_status = :not_added`, `coverage_status = :not_evaluated`, and
`ai_reml_ready = false`.

The candidate rows keep the internal dense GLS oracle as the current covered
same-estimand gate, list a phylolm-style Gaussian phylogenetic REML route as a
fixture-confirmation candidate, and reject generic LMM packages unless they can
match the supplied phylogenetic covariance or precision target.

The focused test now rejects comparator rows whose target is not
`gaussian_loconly_phylo_reml`.

## Mathematical Contract

The comparator gate applies only to the exact Gaussian location-only
phylogenetic mean REML target:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

External packages are not same-estimand evidence unless their fixture matches
this restricted objective, covariance target, boundary behavior, and reported
variance-component estimates.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-gate.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-gate.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-gate.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-gate.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed: 386/386 assertions. `git diff --check` was clean. The
claim-boundary scan hit only the quoted scan command in this after-task report
and the paired check-log entry.

## Tests Of The Tests

The focused test pins the comparator schema, checks the planned/no-dependency
status, verifies that the internal dense GLS row remains the current
same-estimand gate, and confirms that a `:q4_phylo` comparator row is rejected.

## Consistency Audit

No comparator package dependency or optional developer script was added because
no external candidate cleared the same-estimand fixture gate in this slice.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

Nothing material. The slice stayed at schema, tests, and decision documentation.

## Team Learning

Comparator evidence needs target validation before dependency selection. A
package that can fit a related Gaussian mixed model is not enough unless it
matches the same restricted likelihood and covariance target.

## Known Limitations

The external comparator remains planned. There is no optional developer script,
no coverage evidence, no bridge promotion, no q4 or non-Gaussian claim, and no
public AI-REML optimizer claim.

## Next Actions

Design a versioned same-estimand fixture before adding any external comparator
dependency.
