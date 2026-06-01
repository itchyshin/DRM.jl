# Quick inference profile

CPU-aware run: Julia threads = 4, BLAS threads = 1.

| task | fixture | n | params | elapsed/s |
|:-----|:--------|--:|-------:|----------:|
| fit | fixed Gaussian | 600 | 4 | 0.0003 |
| Wald CI | fixed Gaussian | 600 | 4 | 0.0000 |
| profile CI warm | fixed Gaussian | 600 | 4 | 0.0064 |
| bootstrap CI B=20 serial | fixed Gaussian | 600 | 4 | 0.0086 |
| bootstrap CI B=20 threaded | fixed Gaussian | 600 | 4 | 0.0026 |
| bootstrap summary B=20 serial | fixed Gaussian | 600 | 4 | 0.0054 |
| profile curve n=21 | fixed Gaussian | 600 | 21 | 0.0061 |
| parameter surface n=11 cold | fixed Gaussian | 600 | 121 | 0.1949 |
| parameter surface n=11 warm | fixed Gaussian | 600 | 121 | 0.0106 |
| fit | crossed Gaussian | 900 | 5 | 0.1645 |
| profile CI warm | crossed Gaussian | 900 | 5 | 2.7055 |
| profile CI threaded warm | crossed Gaussian | 900 | 5 | 1.0017 |
| profile curve n=21 | crossed Gaussian | 900 | 21 | 0.7233 |
| bootstrap result B=12 serial | Poisson (1|g) | 600 | 3 | 0.1837 |
| bootstrap result B=12 threaded | Poisson (1|g) | 600 | 3 | 0.0787 |

Interpretation guardrails:
- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.
- Profile CI now warm-starts nuisance fits in the production `confint(..., method=:profile)` path.
- Threaded profile max endpoint delta versus serial warm profile CI: 0.000e+00.
- Warm parameter-surface max deviance delta versus cold grid: 2.274e-13; measured speedup 18.44x.
- Threaded bootstrap uses independent per-replicate RNG seeds; timings are only comparable at the explicit thread count above.
- Poisson RE bootstrap accounting: serial used 12/12 (failed 0), threaded used 12/12 (failed 0).
