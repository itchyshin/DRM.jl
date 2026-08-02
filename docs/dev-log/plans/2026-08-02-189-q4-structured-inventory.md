# Inventory — #189 q=4 structured `Q_cond` providers (2026-08-02)

## Marker gate today
- [`src/gaussian_bivariate.jl`](../../../src/gaussian_bivariate.jl) `_bivariate_q4_marker`
  - q=2 (`mu1`+`mu2` only): `:phylo` / `:relmat` / `:animal` → `:structured_q2`
  - q=4 (all four axes): **phylo only** → `:phylo_q4` (L300–307 rejects non-phylo)
- `_split_bivariate_q4_rhs` already *parses* `relmat`/`animal`/`spatial` FunctionTerms
  but error copy still says “exactly one `phylo(1 | group)`”.

## Phylo q=4 path
- `_fit_bivariate_q4_phylo` → `make_problem(phy, …)` → `fit_q4_sparse_tmb(prob, Q_cond)`
- `make_problem` in [`src/sparse_em_fit.jl`](../../../src/sparse_em_fit.jl) builds
  root-conditioned `Q_cond` from `AugmentedPhy`.

## Engine contract
- `fit_q4_sparse_tmb` uses `prob.n_total`, `prob.leaf_node`, designs, responses —
  **never** `prob.phy` (confirmed by grep).
- `AugProblem.phy` is type-required only; a placeholder `AugmentedPhy` is enough
  for level-indexed fits without editing `sparse_aug_plsm.jl`.

## Univariate / q=2 reuse
- Relmat/animal covariance → precision: `make_coevo_problem_from_covariance` in
  [`src/coevolution_q.jl`](../../../src/coevolution_q.jl) (`Q = K⁻¹`).
- Spatial kernel: `_fit_spatial_gaussian` in
  [`src/gaussian_structured.jl`](../../../src/gaussian_structured.jl)
  (`K(ρ)=exp(-d/ρ)+jitter`).
- Group index: `_group_index` in `gaussian_ranef.jl`.

## Bootstrap
- [`src/bootstrap_q4_phylo.jl`](../../../src/bootstrap_q4_phylo.jl) requires
  `re.phy` + tip `leaf_pos`. Non-tree providers: clear ArgumentError (out of scope).

## Tests to mirror
- `test/test_gaussian_bivariate_phylo.jl` — public phylo smoke + validation.
- New: `test/test_gaussian_bivariate_q4_structured.jl`.
