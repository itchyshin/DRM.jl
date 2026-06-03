# Quick inference profile

CPU-aware run: Julia threads = 4, BLAS threads = 1.

| task | fixture | n | params | elapsed/s |
|:-----|:--------|--:|-------:|----------:|
| fit | fixed Gaussian | 600 | 4 | 0.0005 |
| Wald CI | fixed Gaussian | 600 | 4 | 0.0000 |
| profile CI warm | fixed Gaussian | 600 | 4 | 0.0053 |
| bootstrap CI B=20 serial | fixed Gaussian | 600 | 4 | 0.0079 |
| bootstrap CI B=20 threaded | fixed Gaussian | 600 | 4 | 0.0024 |
| bootstrap summary B=20 serial | fixed Gaussian | 600 | 4 | 0.0056 |
| profile curve n=21 | fixed Gaussian | 600 | 21 | 0.0064 |
| parameter surface n=11 cold | fixed Gaussian | 600 | 121 | 0.2050 |
| parameter surface n=11 warm | fixed Gaussian | 600 | 121 | 0.0120 |
| fit | crossed Gaussian | 900 | 5 | 0.1048 |
| profile CI warm | crossed Gaussian | 900 | 5 | 0.3711 |
| profile CI threaded warm | crossed Gaussian | 900 | 5 | 0.1703 |
| profile curve n=21 | crossed Gaussian | 900 | 21 | 0.0900 |
| profile result resd serial | Poisson (1|g) | 600 | 1 | 0.0203 |
| profile result resd threaded endpoints | Poisson (1|g) | 600 | 1 | 0.0121 |
| bootstrap result B=12 serial | Poisson (1|g) | 600 | 3 | 0.1873 |
| bootstrap result B=12 threaded | Poisson (1|g) | 600 | 3 | 0.0788 |

Interpretation guardrails:
- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.
- Profile CI now warm-starts nuisance fits in the production `confint(..., method=:profile)` path.
- Threaded profile max endpoint delta versus serial warm profile CI: 0.000e+00.
- Warm parameter-surface max deviance delta versus cold grid: 2.274e-13; measured speedup 17.08x.
- Threaded bootstrap uses independent per-replicate RNG seeds; timings are only comparable at the explicit thread count above.
- Poisson RE profile endpoint-thread max CI delta versus serial: 0.000e+00; serial endpoint evaluations 14, threaded worker threads 2.
- Poisson RE bootstrap accounting: serial used 12/12 (failed 0), threaded used 12/12 (failed 0).
