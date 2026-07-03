# After Task: Exact-Gaussian Structured Source Map

## Goal

Map the next exact-Gaussian sparse candidate for later row-contract transfer
without implementing a new estimator or promoting REML/AI-REML claims.

## Implemented

Added a scout note:

- `docs/dev-log/scout/2026-06-22-exact-gaussian-structured-source-map.md`

The note maps two exact-Gaussian sparse routes:

- `loconly_gaussian_phylo_reml` in `src/location_only.jl`, the current
  row-contract donor for exact-Gaussian location-only REML diagnostics.
- `two_structured_gaussian_sparse` in `src/gaussian_structured.jl`, the next
  candidate for later row-shaped diagnostics because it uses a sparse augmented
  Gaussian route, Woodbury identities, and Takahashi selected inverse entries.

The validation-status README now points to the source-map scout note.

## Files Changed

- `docs/dev-log/scout/2026-06-22-exact-gaussian-structured-source-map.md`
- `docs/dev-log/validation-status/README.md`
- `docs/dev-log/check-log.d/2026-06-22-exact-gaussian-structured-source-map.md`
- `docs/dev-log/after-task/2026-06-22-exact-gaussian-structured-source-map.md`

## Checks Run

```sh
julia --project=. test/test_two_structured_gaussian_sparse.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" docs/dev-log/scout/2026-06-22-exact-gaussian-structured-source-map.md docs/dev-log/validation-status/README.md docs/dev-log/check-log.d/2026-06-22-exact-gaussian-structured-source-map.md docs/dev-log/after-task/2026-06-22-exact-gaussian-structured-source-map.md
```

The focused two-structured sparse Gaussian test passed locally: 46/46
assertions. `git diff --check` was clean. The claim-boundary scan hit only the
quoted scan command in this after-task report and the paired check-log entry.

## Consistency Audit

This is a source-map slice. It does not relabel the two-structured Gaussian ML
route as REML/AI-REML, does not promote q4, does not promote the R bridge, does
not evaluate interval coverage, does not touch non-Gaussian/Laplace routes, and
does not change any Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Decide in S020 whether to expose this map in Documenter developer notes while
preserving the same claim boundaries.
