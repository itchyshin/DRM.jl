# After-task: Poisson phylo sparse Laplace (#80)

## Scope

Implemented the first non-Gaussian phylogenetic mean model in DRM.jl:

- `drm(bf(@formula(y ~ x + phylo(1 | species))), Poisson(); data, tree, se)`
- Sparse root-conditioned augmented-tree precision for the latent phylogenetic
  random intercept.
- Analytic sparse-Laplace outer gradient using Takahashi selected inverse.
- Paired Julia/drmTMB benchmark harness and report.

Not implemented in this slice:

- NB2/Gamma/Beta/Binomial phylogenetic structured effects.
- Zero-inflated or hurdle Poisson with phylogenetic random effects.
- `relmat`, `animal`, or `spatial` structured count models.
- Random slopes or multiple structured non-Gaussian components.

## Evidence

Focused implementation test:

```sh
julia --project=. test/test_poisson_phylo_laplace.jl
```

Result: 6/6 passing. This includes public routing/recovery and an analytic
gradient check against central finite differences on a small tree.

Full suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
git diff --check
```

Result: `Pkg.test()` passed. `git diff --check` passed. Existing warning
observed during the suite: the pre-existing `rtnb` helper overwrite warning from
the hurdle/truncated-NB tests.

Template q4 sparse-engine gate:

```sh
julia --project=bench bench/run_sparse_tmb_nd.jl
```

Result: not runnable from this checkout. The script fails before fitting because
it includes missing `bench/fit_q4_sparse_tmb.jl`; adjacent q4 bench runners also
reference missing `bench/sparse_em_fit.jl` / `bench/fit_ml_q4.jl`. This slice did
not modify those pre-existing runners.

Paired benchmark:

```sh
Rscript bench/R/gen_phylo_poisson.R
julia --project=bench bench/fit_phylo_poisson.jl
Rscript bench/R/fit_phylo_poisson.R
Rscript bench/R/compare_phylo_poisson.R
```

Report: `report/phylo-poisson-benchmark.md`

Measured R/Julia median speedup: 1.82x (min 1.40x, max 1.96x).

| cell | p | n | R med/s | Julia med/s | speedup |
|:-----|--:|--:|--------:|------------:|--------:|
| phylo_p100 | 100 | 500 | 0.0800 | 0.0430 | 1.86x |
| phylo_p500 | 500 | 1500 | 0.3590 | 0.2021 | 1.78x |
| phylo_p1000 | 1000 | 2000 | 0.5930 | 0.4244 | 1.40x |
| phylo_p2000 | 2000 | 4000 | 1.5835 | 0.8074 | 1.96x |

All paired cells converged in both engines. Log-likelihoods, mean coefficients,
and phylogenetic SD estimates match to numerical tolerance in every cell.

## Rose Audit

- Speedups are measured from generated JSON benchmark outputs, not extrapolated.
- The result is a real non-Gaussian phylo speedup, but it is modest: the p>=1000
  "at least 2x in every cell" gate fails because p=1000 is 1.40x.
- Scope remains Poisson mean `phylo(1 | species)` only; the report and check-log
  do not generalize to NB2 phylo or other non-Gaussian structured markers.
- R parity uses generated fixtures and fitted outputs only. No drmTMB GPL source
  was vendored into DRM.jl.
