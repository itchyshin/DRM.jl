# Design — #189 q=4 structured coevolution providers (2026-08-02)

## Goal
Route `relmat` / `animal` / `spatial` markers on all four bivariate axes through
the verified `fit_q4_sparse_tmb(prob, Q_cond)` engine.

## Problem assembly
Add `make_problem_from_Q(Q_cond, y1, y2, X1, X2, Xs1, Xs2, Xr; group)` in
`src/sparse_em_fit.jl`:

- `Q_cond` is a G×G SPD precision (sparse or dense → sparse).
- `group[i]` maps data row `i` → level in `1:G`.
- Build `AugProblem` with `n_total = G`, `leaf_node = group`, and a
  **placeholder** `AugmentedPhy` (engine never reads `phy` during the Laplace fit).
- Phylo path keeps `make_problem` unchanged.

## Marker / dispatch
- Extend `_bivariate_q4_marker`: when all four axes share kind ∈
  `{relmat, animal, spatial}`, return
  `(:structured_q4, kind, group, lc_zero)`.
- Phylo remains `(:phylo_q4, group, lc_zero)`.
- `drm(...)` dispatches `:structured_q4` → `_fit_bivariate_q4_structured`.

## Provider resolution
- **relmat**: `K` → `Q = inv(K)` (Cholesky).
- **animal**: `A` → same.
- **spatial**: fixed range ρ from keyword `spatial_range` (default = mean
  pairwise site distance). `K_ij = exp(-d_ij/ρ) + 1e-8·I`, then `Q = inv(K)`.
  Joint ρ estimation is deferred (honest under-run note).

## Fit stash
`fit.ranef` stores `Sigma_a`, `Q_cond`, `structured_type`, `group`,
`group_index`, `prob`; `phy = nothing`; `species = Int[]` for non-tree.

## Bootstrap fence
`bootstrap_sigma_a` requires `re.phy isa AugmentedPhy`; otherwise throw
pointing at non-tree follow-on.

## Untouched
`fit_q4_sparse_tmb.jl`, `sparse_aug_plsm.jl`, Takahashi, `lc_metric.jl`.
