# After-task: #189 q=4 coevolution from spatial / relmat / animal

Date: 2026-08-02 · closes #189

## Summary

Routed bivariate q=4 coevolution through level-indexed structured providers
(`relmat`, `animal`, fixed-range `spatial`) by adding `make_problem_from_Q` and
`_fit_bivariate_q4_structured`, reusing the verified `fit_q4_sparse_tmb`
engine. No edits to `fit_q4_sparse_tmb.jl` / `sparse_aug_plsm.jl`.

## What landed

- `make_problem_from_Q` in `src/sparse_em_fit.jl` (placeholder `AugmentedPhy`
  for the typed `AugProblem.phy` field; engine never reads it).
- Marker gate accepts four-axis `relmat` / `animal` / `spatial` →
  `:structured_q4`.
- Spatial: fixed `spatial_range` (default = mean pairwise distance).
- `bootstrap_sigma_a` rejects non-tree fits with a clear ArgumentError.
- Tests: `test/test_gaussian_bivariate_q4_structured.jl` (26 pass).
- Docs: capabilities sync + bivariate-coscale worked example; design/inventory
  plans under `docs/dev-log/plans/`.

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| Supported for Gaussian q=4 structured coevolution providers | **PASS** — tests green |
| Speed / 2.18× / O(p) unchanged | **PASS** — engine core untouched; no new speed headline |
| Spatial range jointly estimated | **REJECT** — fixed-ρ only; documented |
| Non-tree bootstrap CIs | **REJECT** — fenced ArgumentError |
| Registrator / General | **OUT** — D-111 |

## Not covered

- Joint spatial ρ estimation; non-tree bootstrap; drmTMB R-bridge cells;
  #366 merge (docs idle handover still CI-pending at close of this slice).

## Verify

```bash
julia --project=. -e 'using Test; @testset "all" begin include("test/test_gaussian_bivariate_q4_structured.jl") end'
# → 26 passed
```
