# NB2 phylo sparse-Laplace benchmark

Measured median speedup R/Julia: 57.83x (min 21.87x, max 71.21x)

| cell | p | n | R med/s | Julia med/s | speedup | |dLL| | max|dβ| | |dTheta| | |dSD| | conv R/J |
|:-----|--:|--:|--------:|------------:|--------:|------:|--------:|--------:|------:|:---------|
| phylo_p100  |   100 |   500 |    0.5880 |    0.0083 |   71.21x | 1.251e-11 | 3.655e-07 |    0.000 |    0.000 | TRUE/TRUE |
| phylo_p500  |   500 |  1500 |    2.3690 |    0.0343 |   69.09x | 6.844e-11 | 4.747e-08 |    0.000 |    0.000 | TRUE/TRUE |
| phylo_p1000 |  1000 |  2000 |    3.9150 |    0.0841 |   46.58x | 1.537e-10 | 1.019e-06 |    0.000 |    0.000 | TRUE/TRUE |
| phylo_p2000 |  2000 |  4000 |    7.4940 |    0.3427 |   21.87x | 2.157e-09 | 9.854e-06 |    0.000 |    0.000 | TRUE/TRUE |

## Gates

- Both engines converge in every measured cell: PASS
- Julia faster than drmTMB in every measured cell: PASS
- p >= 1000 cells at least 2x faster: PASS
- Likelihood/estimate parity on reported metrics: PASS
- CPU-aware timing: both engines are run without post-fit SE/sdreport; Julia pins BLAS to one thread and uses `g_tol = 1e-6` for the benchmark fits.
- Scale note: drmTMB reports NB2 public `sigma`; this report converts it to size `theta = 1 / sigma^2` before comparing with DRM.jl's current NB2 `sigma` slot.
- Scope: NB2 mean model with `phylo(1 | species)` and `sigma ~ 1` only; no `zi`/`hu`, structured `sigma`, or q>1 non-Gaussian phylo model is claimed here.
- All speedups above are measured from the JSON result files, not extrapolated.

