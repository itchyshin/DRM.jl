# Poisson phylo sparse-Laplace benchmark

Measured median speedup R/Julia: 1.82x (min 1.40x, max 1.96x)

| cell | p | n | R med/s | Julia med/s | speedup | |dLL| | max|dβ| | |dSD| | conv R/J |
|:-----|--:|--:|--------:|------------:|--------:|------:|--------:|------:|:---------|
| phylo_p100  |   100 |   500 |    0.0800 |    0.0430 |    1.86x | 2.492e-09 | 2.440e-06 |    0.000 | TRUE/TRUE |
| phylo_p500  |   500 |  1500 |    0.3590 |    0.2021 |    1.78x | 2.228e-10 | 1.655e-06 |    0.000 | TRUE/TRUE |
| phylo_p1000 |  1000 |  2000 |    0.5930 |    0.4244 |    1.40x | 1.115e-08 | 1.509e-06 |    0.000 | TRUE/TRUE |
| phylo_p2000 |  2000 |  4000 |    1.5835 |    0.8074 |    1.96x | 1.601e-09 | 3.187e-08 |    0.000 | TRUE/TRUE |

## Gates

- Both engines converge in every measured cell: PASS
- Julia faster than drmTMB in every measured cell: PASS
- p >= 1000 cells at least 2x faster: FAIL
- CPU-aware timing: both engines are run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- Scope: Poisson mean model with `phylo(1 | species)` only; no `zi`/`hu`, NB2 phylo, or non-phylo structured count model is claimed here.
- All speedups above are measured from the JSON result files, not extrapolated.

