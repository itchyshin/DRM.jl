# After-task: Non-Gaussian phylo speed verification (#80 follow-on)

## Scope

Verified the current non-Gaussian phylo stack against the R counterpart where a
same-route counterpart exists:

- Poisson `phylo(1 | species)`
- NB2 `phylo(1 | species)` with `sigma ~ 1`
- Gamma `phylo(1 | species)` with `sigma ~ 1` support status
- Beta `phylo(1 | species)` with `sigma ~ 1` support status
- Binomial `phylo(1 | species)` support status

No implementation code changed in this verification slice.

## Evidence

Paired Poisson benchmark:

```sh
Rscript bench/R/gen_phylo_poisson.R
Rscript bench/R/fit_phylo_poisson.R
julia --project=bench bench/fit_phylo_poisson.jl
Rscript bench/R/compare_phylo_poisson.R
```

Result: DRM.jl faster in every measured cell. Median speedup 1.65x; range
1.39x-1.89x. Both engines converged in every measured cell and likelihood /
estimate parity passed. The 2x large-p gate did not pass.

Paired NB2 benchmark:

```sh
Rscript bench/R/gen_phylo_nb2.R
Rscript bench/R/fit_phylo_nb2.R
julia --project=bench bench/fit_phylo_nb2.jl
Rscript bench/R/compare_phylo_nb2.R
```

Result: DRM.jl faster in every measured cell. Median speedup 58.11x; range
28.23x-71.60x. Both engines converged in every measured cell and likelihood /
estimate parity passed.

Gamma/Beta support and timing:

```sh
julia --project=bench bench/fit_phylo_gamma_beta.jl
Rscript bench/R/smoke_phylo_gamma_beta.R
Rscript bench/R/compare_phylo_gamma_beta.R
```

Result: Julia converged in every timing cell. Gamma median Julia time 0.1303s;
Beta median Julia time 0.1075s. Local-source drmTMB rejects both phylo routes, so
no speedup ratio is available.

Binomial support and timing:

```sh
julia --project=bench bench/fit_phylo_binomial.jl
Rscript bench/R/smoke_phylo_binomial.R
Rscript bench/R/compare_phylo_binomial.R
```

Result: Julia converged in every timing cell. Median Julia time 0.0602s.
Local-source drmTMB rejects the Binomial phylo route, so no speedup ratio is
available.

Installed `drmTMB` check:

```sh
Rscript -e 'library(drmTMB); packageVersion("drmTMB")'
```

Result: installed `drmTMB` is 0.1.3.9000. Tiny installed-package smokes reject
Gamma, Beta, and Binomial phylo routes as well.

Whitespace validation:

```sh
git diff --check
```

Result: passed.

## Rose Audit

- Speedup is claimed only for same-route paired comparisons.
- Poisson and NB2 speedups are measured from regenerated JSON outputs, not
  extrapolated.
- Gamma, Beta, and Binomial are reported as fast Julia routes but not as faster
  than R, because the current R counterpart rejects the same phylo models.
- No drmTMB GPL source was vendored into DRM.jl.
