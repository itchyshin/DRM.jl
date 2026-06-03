# After-task: Gamma/Beta phylo sparse Laplace (#80 follow-on)

## Scope

Implemented two constant-scale non-Gaussian phylogenetic mean models in DRM.jl:

- `drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
  Gamma(); data, tree, se)`
- `drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
  Beta(); data, tree, se)`

Both routes reuse the sparse root-conditioned phylogenetic precision, the
mean-plus-nuisance sparse-Laplace helper, and analytic nuisance-gradient
corrections. The public `sigma` slot remains on the drmTMB-compatible scale:
Gamma shape `alpha = 1 / sigma^2`, Beta precision `phi = 1 / sigma^2`.

Not implemented in this slice:

- Binomial-style phylogenetic models with no nuisance parameter.
- Gamma/Beta structured `sigma`, q>1 non-Gaussian phylo blocks, random slopes,
  or multiple structured non-Gaussian components.
- Zero-inflated, hurdle, zero-one, or beta-binomial phylogenetic variants.
- `relmat`, `animal`, or `spatial` structured Gamma/Beta models.

## Evidence

Focused implementation test:

```sh
julia --project=. test/test_gamma_beta_phylo_laplace.jl
```

Result: 16/16 passing in the last focused run before final package checks. This
includes public routing/recovery for Gamma and Beta, non-constant `sigma`
rejections, and analytic sparse-Laplace gradient checks against central finite
differences on small trees.

Julia timing benchmark:

```sh
julia --project=bench bench/fit_phylo_gamma_beta.jl
```

Report: `report/phylo-gamma-beta-benchmark.md`

| family | cell | p | n | Julia med/s | converged |
|:-------|:-----|--:|--:|------------:|:----------|
| gamma | phylo_p128 | 128 | 512 | 0.0304 | TRUE |
| beta | phylo_p128 | 128 | 512 | 0.0187 | TRUE |
| gamma | phylo_p512 | 512 | 1536 | 0.0942 | TRUE |
| beta | phylo_p512 | 512 | 1536 | 0.0752 | TRUE |
| gamma | phylo_p1024 | 1024 | 2048 | 0.1685 | TRUE |
| beta | phylo_p1024 | 1024 | 2048 | 0.1551 | TRUE |
| gamma | phylo_p2048 | 2048 | 4096 | 0.4256 | TRUE |
| beta | phylo_p2048 | 2048 | 4096 | 0.3086 | TRUE |

Family median Julia times: Gamma 0.1313s; Beta 0.1152s.

R support smoke:

```sh
Rscript bench/R/smoke_phylo_gamma_beta.R
Rscript bench/R/compare_phylo_gamma_beta.R
```

Result: local-source drmTMB rejects both Gamma and Beta
`phylo(1 | species)` models, so an R/Julia speedup ratio is unavailable for
this slice.

Full suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `Pkg.test()` passed. Existing warning observed during the suite: the
pre-existing `rtnb` helper overwrite warning from the hurdle/truncated-NB tests.

Check-log and whitespace validation:

```sh
julia tools/build_check_log.jl --check
git diff --check
```

Result: both passed.

## Rose Audit

- The benchmark report uses generated JSON timing/support artifacts, not
  extrapolated numbers.
- A speedup headline is intentionally not claimed: the R counterpart cannot fit
  the same Gamma/Beta phylo route today.
- Scope remains Gamma/Beta mean `phylo(1 | species)` with `sigma ~ 1` only. The
  report and check-log do not generalize to binomial phylo, structured `sigma`,
  q>1 non-Gaussian phylo, or other structured-effect markers.
- R parity uses a local-source support smoke only. No drmTMB GPL source was
  vendored into DRM.jl.
