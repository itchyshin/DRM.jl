# Gamma/Beta phylo sparse-Laplace benchmark

beta median Julia time 0.1152s; gamma median Julia time 0.1313s

Local-source drmTMB currently rejects Gamma and Beta `phylo(1 | species)` models, so an R/Julia speedup ratio is unavailable for this slice.

## Julia timings

| family | cell | p | n | Julia med/s | logLik | sigma | phylo SD | converged |
|:-------|:-----|--:|--:|------------:|-------:|------:|---------:|:----------|
| gamma | phylo_p128  |   128 |   512 |    0.0304 |  -475.662 |   0.467 |   0.512 | TRUE |
| beta  | phylo_p128  |   128 |   512 |    0.0187 |   321.077 |   0.255 |   0.294 | TRUE |
| gamma | phylo_p512  |   512 |  1536 |    0.0942 | -1337.164 |   0.465 |   0.425 | TRUE |
| beta  | phylo_p512  |   512 |  1536 |    0.0752 |   931.696 |   0.268 |   0.196 | TRUE |
| gamma | phylo_p1024 |  1024 |  2048 |    0.1685 | -1854.380 |   0.530 |   0.141 | TRUE |
| beta  | phylo_p1024 |  1024 |  2048 |    0.1551 |  1234.019 |   0.282 |   0.039 | TRUE |
| gamma | phylo_p2048 |  2048 |  4096 |    0.4256 | -3870.084 |   0.515 |   0.257 | TRUE |
| beta  | phylo_p2048 |  2048 |  4096 |    0.3086 |  2493.992 |   0.273 |   0.133 | TRUE |

## R support smoke

- `gamma`: unsupported
- `beta`: unsupported

## Gates

- Julia converges in every measured cell: PASS
- R counterpart speedup available: FAIL - local-source drmTMB rejects both Gamma and Beta phylo today.
- CPU-aware timing: Julia is run without post-fit SE/sdreport, pins BLAS to one thread, and uses `g_tol = 1e-6` for timing fits.
- Scope: Gamma/Beta mean models with `phylo(1 | species)` and `sigma ~ 1` only; no structured `sigma`, q>1 non-Gaussian phylo, or binomial-style no-nuisance model is claimed here.
- Recovery and gradient correctness are covered by `test/test_gamma_beta_phylo_laplace.jl`; this report is a timing/support-status artifact.

