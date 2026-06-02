# After-task: crossed-family sparse Laplace (#107 under #80)

## Scope

Extended the crossed random-intercept sparse-Laplace engine beyond Poisson for
the first practical #80 slice.

Implemented:

- Binomial crossed random intercepts through the generic crossed mean engine.
- NB2 crossed random intercepts with estimated size.
- Gamma crossed random intercepts with estimated shape.
- Beta crossed random intercepts with estimated precision.
- Minimal public routing for multiple intercept terms in Binomial, NB2, Gamma,
  and Beta.
- Paired Julia/drmTMB benchmark scripts for the crossed-family grid.

Not implemented in this slice:

- Crossed correlated slopes.
- Structured `relmat` / `phylo` / `spatial` priors for non-Gaussian means.
- Fully analytic nuisance-parameter gradients.
- Public claims for drmTMB parity where drmTMB currently rejects the model.

## Evidence

Focused tests:

```sh
julia --project=. test/test_crossed_laplace_generic.jl
```

Result: 37/37 passing.

Julia family profile:

```sh
julia --project=bench bench/profile_crossed_laplace.jl
```

Medium-cell medians:

- Poisson: 0.0286 s
- Binomial: 0.3895 s
- NB2: 0.2119 s
- Gamma: 0.1906 s
- Beta: 1.1057 s

Paired drmTMB comparison:

```sh
julia --project=bench bench/gen_crossed_family.jl
julia --project=bench bench/fit_crossed_family.jl
Rscript bench/R/fit_crossed_family.R
Rscript bench/R/compare_crossed_family.R
```

Successful paired cells were Poisson and NB2. Median R/Julia speedup across
successful paired cells was 45.35x (min 34.08x, max 115.99x). Coefficient,
random-effect SD, nuisance, and log-likelihood parity passed on those cells.

drmTMB rejected Binomial, Gamma, and Beta crossed random effects in this local
target; those failures are recorded in `report/crossed-family-benchmark.md`.

## Guardrails

- Timings are measured from local JSON results, not extrapolated.
- Beta is skipped above n=5000 in the quick Julia profile because the exact beta
  third-derivative path is dominated by `polygamma`.
- One large Gamma profile row had accurate estimates but a conservative
  convergence flag; treat that as an optimisation-hardening target, not a
  public headline.
