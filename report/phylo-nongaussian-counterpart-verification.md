# Non-Gaussian phylo counterpart verification

Verification date: 2026-06-03.

DRM.jl branch: `codex/nongaussian-phylo-speed-verification`, stacked on
`codex/binomial-phylo-benchmark`.

R counterpart basis:

- Paired Poisson/NB2 benchmarks used installed `drmTMB` 0.1.3.9000 from
  `/Users/z3437171/R/x86_64-pc-linux-gnu-library/4.4/drmTMB`.
- Installed-package support smokes also reject Gamma, Beta, and Binomial phylo
  routes. The local-source smoke scripts give the same unsupported conclusion.

## Answer

Not all non-Gaussian phylo families can currently be compared against the R
counterpart. Among the families where drmTMB can fit the same model, DRM.jl is
faster in every measured cell. For Gamma, Beta, and Binomial, the current R
counterpart rejects the phylo route, so a speedup ratio is unavailable.

| family | same-route R counterpart? | paired speed result | Julia timing status | conclusion |
|:-------|:--------------------------|:--------------------|:--------------------|:-----------|
| Poisson | yes | 1.65x median speedup; range 1.39x-1.89x | all Julia cells converged | faster in every measured paired cell, but not a 2x large-p result |
| NB2 | yes | 58.11x median speedup; range 28.23x-71.60x | all Julia cells converged | clearly faster, with likelihood/estimate parity |
| Gamma | no | unavailable | median Julia time 0.1303s; all cells converged | cannot claim faster; counterpart rejects the route |
| Beta | no | unavailable | median Julia time 0.1075s; all cells converged | cannot claim faster; counterpart rejects the route |
| Binomial | no | unavailable | median Julia time 0.0602s; all cells converged | cannot claim faster; counterpart rejects the route |

## Commands

Paired Poisson verification:

```sh
Rscript bench/R/gen_phylo_poisson.R
Rscript bench/R/fit_phylo_poisson.R
julia --project=bench bench/fit_phylo_poisson.jl
Rscript bench/R/compare_phylo_poisson.R
```

Paired NB2 verification:

```sh
Rscript bench/R/gen_phylo_nb2.R
Rscript bench/R/fit_phylo_nb2.R
julia --project=bench bench/fit_phylo_nb2.jl
Rscript bench/R/compare_phylo_nb2.R
```

Gamma/Beta support and timing verification:

```sh
julia --project=bench bench/fit_phylo_gamma_beta.jl
Rscript bench/R/smoke_phylo_gamma_beta.R
Rscript bench/R/compare_phylo_gamma_beta.R
```

Binomial support and timing verification:

```sh
julia --project=bench bench/fit_phylo_binomial.jl
Rscript bench/R/smoke_phylo_binomial.R
Rscript bench/R/compare_phylo_binomial.R
```

Installed-package support smoke:

```sh
Rscript -e 'library(drmTMB); packageVersion("drmTMB")'
```

Then tiny installed-package fits were attempted for Gamma, Beta, and Binomial
`phylo(1 | species)`. Gamma and Beta failed at the structured-effect guard; the
Binomial fit failed because that route is outside the current supported family
set.

## Report Links

- `report/phylo-poisson-benchmark.md`
- `report/phylo-nb2-benchmark.md`
- `report/phylo-gamma-beta-benchmark.md`
- `report/phylo-binomial-benchmark.md`
