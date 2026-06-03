# After-task: NB2 phylo sparse Laplace (#70 follow-on)

## Scope

Implemented the next non-Gaussian phylogenetic mean model in DRM.jl:

- `drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
  NegBinomial2(); data, tree, se)`
- Sparse root-conditioned augmented-tree precision for the latent phylogenetic
  random intercept.
- Analytic sparse-Laplace outer gradient with a fitted NB2 nuisance parameter
  and Takahashi selected inverse.
- Paired Julia/drmTMB benchmark harness and report.

The new phylo mean+nuisance helper is family-generic enough to be reused by the
next constant-scale non-Gaussian families, but this slice wires only NB2.

Not implemented in this slice:

- Gamma/Beta/Binomial phylogenetic structured effects.
- Zero-inflated or hurdle NB2 with phylogenetic random effects.
- NB2 structured `sigma`, q>1 non-Gaussian phylo blocks, random slopes, or
  multiple structured non-Gaussian components.
- `relmat`, `animal`, or `spatial` structured NB2 models.

## Evidence

Focused implementation test:

```sh
julia --project=. test/test_nb2_phylo_laplace.jl
```

Result: 8/8 passing. This includes public routing/recovery, a non-constant
`sigma` rejection, and an analytic gradient check against central finite
differences on a small tree.

Regression guard around reused sparse-Laplace paths:

```sh
julia --project=. -e 'include("test/test_poisson_phylo_laplace.jl"); include("test/test_crossed_laplace_generic.jl")'
```

Result: Poisson phylo and generic crossed sparse-Laplace tests passed.

Full suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `Pkg.test()` passed. Existing warning observed during the suite: the
pre-existing `rtnb` helper overwrite warning from the hurdle/truncated-NB tests.

Paired benchmark:

```sh
Rscript bench/R/gen_phylo_nb2.R
Rscript bench/R/fit_phylo_nb2.R
julia --project=bench bench/fit_phylo_nb2.jl
Rscript bench/R/compare_phylo_nb2.R
```

The R side used the local drmTMB source checkout when available:
`/Users/z3437171/Dropbox/Github Local/drmTMB` at commit `a7f722ad`.

Report: `report/phylo-nb2-benchmark.md`

Measured R/Julia median speedup: 57.83x (min 21.87x, max 71.21x).

| cell | p | n | R med/s | Julia med/s | speedup |
|:-----|--:|--:|--------:|------------:|--------:|
| phylo_p100 | 100 | 500 | 0.5880 | 0.0083 | 71.21x |
| phylo_p500 | 500 | 1500 | 2.3690 | 0.0343 | 69.09x |
| phylo_p1000 | 1000 | 2000 | 3.9150 | 0.0841 | 46.58x |
| phylo_p2000 | 2000 | 4000 | 7.4940 | 0.3427 | 21.87x |

All paired cells converged in both engines. Log-likelihoods, mean coefficients,
converted NB2 size, and phylogenetic SD estimates match to numerical tolerance
in every cell.

## Rose Audit

- Speedups are measured from generated JSON benchmark outputs, not extrapolated.
- The result is a strong non-Gaussian phylo speedup: every measured cell is more
  than 20x faster than local-source drmTMB, and the p >= 1000 cells pass the
  "at least 2x faster" gate.
- Scope remains NB2 mean `phylo(1 | species)` with `sigma ~ 1` only; the report
  and check-log do not generalize to Gamma/Beta/Binomial phylo, zero-inflated or
  hurdle NB2, structured `sigma`, q>1 non-Gaussian phylo, or other structured
  non-Gaussian markers.
- drmTMB reports NB2 public `sigma`, while current DRM.jl stores NB2 size in the
  `sigma` slot. The benchmark report converts drmTMB `sigma` to
  `theta = 1 / sigma^2` before comparing estimates.
- R parity uses generated fixtures and fitted outputs only. No drmTMB GPL source
  was vendored into DRM.jl.
