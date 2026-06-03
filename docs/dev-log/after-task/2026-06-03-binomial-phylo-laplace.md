# After-task: Binomial phylo sparse Laplace (#80 follow-on)

## Scope

Implemented the no-nuisance non-Gaussian phylogenetic mean model in DRM.jl:

- `drm(bf(@formula(cbind(successes, failures) ~ x + phylo(1 | species))),
  Binomial(); data, tree, se)`
- `drm(bf(@formula(y ~ x + phylo(1 | species))),
  Binomial(); data, tree, se)` for Bernoulli 0/1 responses.

This slice adds a generic no-nuisance phylo sparse-Laplace helper using the
existing per-family `_laplace_v123` callbacks and wires only `Binomial()` to it.
The public route remains mean-only: there is no `sigma`/dispersion formula.

Not implemented in this slice:

- Binomial structured `sigma` or nuisance-parameter routes; Binomial is
  mean-only.
- q>1 non-Gaussian phylo blocks, random slopes, or multiple structured
  non-Gaussian components.
- Zero-inflated, hurdle, beta-binomial, or zero-one phylogenetic variants.
- `relmat`, `animal`, or `spatial` structured Binomial models.

## Evidence

Focused implementation test:

```sh
julia --project=. test/test_binomial_phylo_laplace.jl
```

Result: 12/12 passing. This includes public routing/recovery for cbind and
Bernoulli responses, rejection of mixed phylo plus ordinary random effects, and
an analytic sparse-Laplace gradient check against central finite differences on
a small tree.

Julia timing benchmark:

```sh
julia --project=bench bench/fit_phylo_binomial.jl
```

Report: `report/phylo-binomial-benchmark.md`

| cell | p | n | Julia med/s | converged |
|:-----|--:|--:|------------:|:----------|
| phylo_p128 | 128 | 512 | 0.0125 | TRUE |
| phylo_p512 | 512 | 1536 | 0.0478 | TRUE |
| phylo_p1024 | 1024 | 2048 | 0.0706 | TRUE |
| phylo_p2048 | 2048 | 4096 | 0.1181 | TRUE |

Median Julia time: 0.0592s.

R support smoke:

```sh
Rscript bench/R/smoke_phylo_binomial.R
Rscript bench/R/compare_phylo_binomial.R
```

Result: local-source drmTMB rejects Binomial `phylo(1 | species)` models, so an
R/Julia speedup ratio is unavailable for this slice.

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
  the same Binomial phylo route today.
- Scope remains Binomial mean `phylo(1 | species)` only. The report and
  check-log do not generalize to nuisance-parameter families, structured
  `sigma`, q>1 non-Gaussian phylo, or other structured-effect markers.
- R parity uses a local-source support smoke only. No drmTMB GPL source was
  vendored into DRM.jl.
