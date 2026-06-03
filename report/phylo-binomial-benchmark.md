# Binomial phylo sparse-Laplace benchmark

median Julia time 0.0592s

Local-source drmTMB currently rejects Binomial `phylo(1 | species)` models, so an R/Julia speedup ratio is unavailable for this slice.

## Julia timings

| cell | p | n | Julia med/s | logLik | phylo SD | converged |
|:-----|--:|--:|------------:|-------:|---------:|:----------|
| phylo_p128  |   128 |   512 |    0.0125 |  -950.894 |   0.485 | TRUE |
| phylo_p512  |   512 |  1536 |    0.0478 | -2820.481 |   0.305 | TRUE |
| phylo_p1024 |  1024 |  2048 |    0.0706 | -3713.637 |   0.190 | TRUE |
| phylo_p2048 |  2048 |  4096 |    0.1181 | -7388.395 |   0.144 | TRUE |

## R support smoke

- `binomial`: unsupported

## Gates

- Julia converges in every measured cell: PASS
- R counterpart speedup available: FAIL - local-source drmTMB rejects Binomial phylo today.
- CPU-aware timing: Julia is run without post-fit SE/sdreport, pins BLAS to one thread, and uses `g_tol = 1e-6` for timing fits.
- Scope: Binomial mean models with `phylo(1 | species)` only; no structured `sigma`, nuisance parameter, q>1 non-Gaussian phylo, or zero/hurdle variant is claimed here.
- Recovery and gradient correctness are covered by `test/test_binomial_phylo_laplace.jl`; this report is a timing/support-status artifact.

