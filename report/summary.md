# drmTMB vs Julia POC benchmark — summary

Median speedup R/Julia: 22.6x, max 83.8x, min 0.1x

| cell_id     |     n | R time/s | Jl time/s               | speedup  |  |dLL|     | max|dCoef|  |
|:------------|------:|---------:|:------------------------|---------:|-----------:|------------:|
| u_small     |   100 |   0.0120 |   0.0001 |    83.8x | 2.332e-05 | 4.781e-05 |
| u_med       |   500 |   0.0240 |   0.0006 |    39.6x | 3.093e-05 | 4.851e-05 |
| u_large     |  2000 |   0.0620 |   0.0027 |    22.6x | 8.832e-06 | 4.132e-05 |
| b_small     |   200 |   0.0170 |   0.0003 |    51.7x | 4.805e-08 | 4.082e-05 |
| b_med       |  1000 |   0.0990 |   0.0051 |    19.6x | 4.389e-06 | 4.932e-05 |
| phylo_p50   |    50 |   0.0510 |   0.0016 |    32.6x | 1.728e-05 | 1.885e-05 |
| phylo_p200  |   200 |   0.1380 |   0.0668 |     2.1x | 2.756e-05 | 2.486e-05 |
| phylo_p500  |   500 |   0.3390 |   0.9322 |     0.4x | 4.742e-05 | 1.023e-05 |
| phylo_p1000 |  1000 |   0.7390 |  10.4258 |     0.1x | 2.158e-05 | 4.238e-05 |
| q4_p100     |   100 |   2.5850 | POC scope: needs Laplace |        - |       - |       - |

## Gate check

- |dLogLik| < 0.001 for all cells: PASS
- max |dCoef| < 0.01 for all cells: PASS
- Median speedup R/Julia: informational, no hard gate at POC stage.

Overall: PASS

