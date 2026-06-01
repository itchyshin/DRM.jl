# Quick inference profile

CPU-aware run: Julia threads = 4, BLAS threads = 1.

| task | fixture | n | params | elapsed/s |
|:-----|:--------|--:|-------:|----------:|
| fit | fixed Gaussian | 600 | 4 | 0.0004 |
| Wald CI | fixed Gaussian | 600 | 4 | 0.0000 |
| profile CI warm | fixed Gaussian | 600 | 4 | 0.0077 |
| bootstrap CI B=20 serial | fixed Gaussian | 600 | 4 | 0.0076 |
| bootstrap CI B=20 threaded | fixed Gaussian | 600 | 4 | 0.0030 |
| bootstrap summary B=20 serial | fixed Gaussian | 600 | 4 | 0.0055 |
| profile curve n=21 | fixed Gaussian | 600 | 21 | 0.0046 |
| parameter surface n=11 cold | fixed Gaussian | 600 | 121 | 0.1856 |
| parameter surface n=11 warm | fixed Gaussian | 600 | 121 | 0.0124 |
| fit | crossed Gaussian | 900 | 5 | 0.1545 |
| profile CI warm | crossed Gaussian | 900 | 5 | 2.3082 |
| profile CI threaded warm | crossed Gaussian | 900 | 5 | 0.9849 |
| profile curve n=21 | crossed Gaussian | 900 | 21 | 0.6688 |

Interpretation guardrails:
- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.
- Profile CI now warm-starts nuisance fits in the production `confint(..., method=:profile)` path.
- Threaded profile max endpoint delta versus serial warm profile CI: 0.000e+00.
- Warm parameter-surface max deviance delta versus cold grid: 2.274e-13; measured speedup 14.99x.
- Threaded bootstrap uses independent per-replicate RNG seeds; timings are only comparable at the explicit thread count above.
