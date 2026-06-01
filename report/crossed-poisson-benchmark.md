# Crossed Poisson sparse-Laplace benchmark (#70)

Measured median speedup R/Julia: 18.21x (min 10.77x, max 35.81x)

| cell | n | kind | R med/s | Julia med/s | speedup | |dLL| | max|dβ| | max|dSD| | conv R/J |
|:-----|--:|:-----|--------:|------------:|--------:|------:|--------:|--------:|:---------|
| single_control |   1500 | single  |    0.1830 |    0.0170 |   10.77x | 1.319e-01 | 7.128e-03 |    0.009 | TRUE/TRUE |
| crossed_small  |   1000 | crossed |    0.2260 |    0.0072 |   31.48x | 2.849e-10 | 1.211e-08 |    0.000 | TRUE/TRUE |
| crossed_medium |   5000 | crossed |    1.0320 |    0.0573 |   18.00x | 1.325e-07 | 1.610e-06 |    0.000 | TRUE/TRUE |
| crossed_large  |  20000 | crossed |    4.4390 |    0.2412 |   18.41x | 1.321e-07 | 6.652e-08 |    0.000 | TRUE/TRUE |
| fixedq_n1000   |   1000 | crossed |    0.2670 |    0.0173 |   15.47x | 1.859e-08 | 2.018e-06 |    0.000 | TRUE/TRUE |
| fixedq_n20000  |  20000 | crossed |    3.9700 |    0.1109 |   35.81x | 1.117e-07 | 1.460e-06 |    0.000 | TRUE/TRUE |

## Gates

- Medium crossed cell Julia faster than drmTMB: PASS
- Medium/large crossed cells at least 2x faster: PASS
- Fixed-q speedup does not degrade as n grows: PASS
- CPU-aware timing: both engines are run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- Correctness gates are reported numerically above; inspect |dLL| separately if constants differ.
- All speedups above are measured from the JSON result files, not extrapolated.

