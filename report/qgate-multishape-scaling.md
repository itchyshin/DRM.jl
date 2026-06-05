# Q-gate multi-shape q4 scaling

Command: `julia --project=bench bench/run_scaling.jl`
Julia threads: 1; BLAS threads: 1.
Shapes: balanced, caterpillar; p grid: 100, 1000, 10000; nrep: 4.

The sampler draws the full augmented state from `P^{-1}` with sparse CHOLMOD (`P = kron(Q_cond, inv(Λ))`), then attaches `nrep` observations per species. Caterpillar branch lengths are scaled so their maximum root-to-tip height matches the balanced tree at the same `p`; this keeps the gate focused on sparse-topology scaling rather than changing the Brownian data scale.

| shape | p | nobs | wall/s | iterations | logLik | logLik/nobs | ms/node | converged | g_resid |
|:------|--:|-----:|-------:|-----------:|-------:|------------:|--------:|:----------|--------:|
| balanced | 100 | 400 | 0.761 | 32 | -765.77 | -1.914 | 3.822 | true | 9.00e-04 |
| balanced | 1000 | 4000 | 7.528 | 21 | -8661.62 | -2.165 | 3.766 | true | 6.61e-04 |
| balanced | 10000 | 40000 | 47.812 | 15 | -92998.68 | -2.325 | 2.391 | true | 7.21e-04 |
| caterpillar | 100 | 400 | 1.027 | 51 | -1082.22 | -2.706 | 5.159 | true | 9.53e-04 |
| caterpillar | 1000 | 4000 | 9.338 | 41 | -9857.10 | -2.464 | 4.671 | true | 9.15e-04 |
| caterpillar | 10000 | 40000 | 68.263 | 20 | -40219.69 | -1.005 | 3.413 | true | 2.79e-04 |

| shape | empirical k in wall ~ p^k |
|:------|--------------------------:|
| balanced | 0.90 |
| caterpillar | 0.91 |

Gate verdict: **PASS**.

Gate criteria:
- every row has a finite wall time and finite log-likelihood;
- every fit reports `converged = true`;
- each shape's empirical exponent is at most 1.6 when at least three `p` values are run.
