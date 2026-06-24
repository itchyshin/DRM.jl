# Scout Note: Location-Only Gaussian REML External Comparator

## Question

What same-estimand external comparator could strengthen the location-only
Gaussian phylogenetic REML diagnostic lane without adding a dependency before
the internal row contract is stable?

## Current Internal Comparator

The focused DRM.jl test already uses a dense same-estimand GLS oracle for the
restricted likelihood and compares sparse Woodbury/Takahashi diagnostics against
that oracle. That is enough for internal exact-Gaussian developer evidence.

## Candidate Comparator Shape

A useful external comparator would need to fit the same model:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

The comparator must expose or allow reconstruction of the same REML objective,
variance-component estimates, convergence status, and boundary behavior. A
different prior, Bayesian estimand, ML objective, or transformed covariance
target is agreement evidence only, not a same-estimand REML comparator.

## Recommendation

Do not add a package dependency in this lane yet. Keep the dense GLS oracle as
the gating comparator and use the versioned same-estimand fixture
`loconly-gaussian-phylo-reml-v1` before selecting an external package. The first
comparator PR should remain developer-only and should not change the public
bridge, q4, non-Gaussian, coverage, or AI-REML readiness claims.

## Candidate Decision Table

| Candidate | Same-estimand status | Dependency decision | Artifact status | Next gate |
| --- | --- | --- | --- | --- |
| DRM.jl dense GLS oracle | same-estimand internal | retain as current gate | covered by focused test | keep as dense oracle |
| phylolm-style Gaussian phylogenetic REML | needs fixture confirmation | do not add yet | fixture defined | probe package/version against fixture |
| generic LMM package | not yet same-estimand | do not add without supplied covariance/precision target match | not applicable | reject or specialize |

The row-shaped status helper `_loconly_reml_external_comparator_status()`
mirrors this table for tests and future artifacts. Its status is deliberately
`external_comparator_status = :planned` and `dependency_status = :not_added`.
The fixture helper `_loconly_reml_external_comparator_fixture()` now records a
small deterministic balanced-tree data set, dense covariance target, and dense
GLS REML reference values. No optional developer script or dependency was added
because no external candidate has yet cleared that fixture gate.

The follow-up version-probe row is now explicit in the same status helper. It
records the unselected phylolm-style candidate, fixture id and fixture version,
required same-estimand evidence, and the blocker
`external_package_version_not_probed`. This banks the package/version probe
contract without selecting a package, adding a dependency, wiring the R bridge,
or changing the AI-REML readiness flag.

`tools/loconly-reml-external-comparator-probe.jl` now writes the optional
developer probe artifact. In the local developer environment it recorded
`phylolm` version 2.6.5, but the row remains `fit_status = not_run`,
`same_estimand_status = requires_fixture_reproduction`, `dependency_status =
not_added`, `coverage_status = not_evaluated`, and `ai_reml_ready = false`.

The current `loconly-gaussian-phylo-reml-v1` fixture is not a same-estimand
input for `phylolm`: it has replicated species rows and observation-level
covariate variation, while `phylolm` is a tip-level phylogenetic linear model.
The fit-feasibility row therefore stays `fit_status = not_run` and blocks on
`repeated_observation_fixture_not_tip_level`.

## Next Gate

Choose a replicate-capable comparator or define a separate tip-level fixture
whose likelihood target is genuinely the same as a `phylolm` fit. The
acceptance check should record the comparator package/version, fixture seed,
target equality, point estimates, boundary labels, and whether the comparator
can report the restricted likelihood directly.
