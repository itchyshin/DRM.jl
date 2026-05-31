# Crossed Poisson sparse-Laplace benchmark (#70)

Measured median speedup R/Julia: 0.72x (min 0.30x, max 13.37x)

| cell | n | kind | R med/s | Julia med/s | speedup | |dLL| | max|dβ| | max|dSD| | conv R/J |
|:-----|--:|:-----|--------:|------------:|--------:|------:|--------:|--------:|:---------|
| single_control |   1500 | single  |    0.1980 |    0.0148 |   13.37x | 1.319e-01 | 7.128e-03 |    0.009 | TRUE/TRUE |
| crossed_small  |   1000 | crossed |    0.2250 |    0.0451 |    4.99x | 2.253e-10 | 1.485e-06 |    0.000 | TRUE/TRUE |
| crossed_medium |   5000 | crossed |    0.9920 |    1.3087 |    0.76x | 1.046e-10 | 2.858e-06 |    0.000 | TRUE/FALSE |
| crossed_large  |  20000 | crossed |    4.4290 |    8.4429 |    0.52x | 8.004e-10 | 1.400e-06 |    0.000 | TRUE/FALSE |
| fixedq_n1000   |   1000 | crossed |    0.2750 |    0.4044 |    0.68x | 1.852e-08 | 2.077e-06 |    0.000 | TRUE/TRUE |
| fixedq_n20000  |  20000 | crossed |    4.2170 |   14.2886 |    0.30x | 1.121e-03 | 9.496e-04 |    0.001 | TRUE/FALSE |

## Gates

- Medium crossed cell Julia faster than drmTMB: FAIL
- Medium/large crossed cells at least 2x faster: FAIL
- Fixed-q speedup does not degrade as n grows: FAIL
- CPU-aware timing: both engines are run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- Correctness gates are reported numerically above; inspect |dLL| separately if constants differ.
- All speedups above are measured from the JSON result files, not extrapolated.

