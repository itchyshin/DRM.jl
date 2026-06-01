# Quick inference profile

CPU-aware run: Julia threads = 4, BLAS threads = 1.

| task | fixture | n | params | elapsed/s |
|:-----|:--------|--:|-------:|----------:|
| fit | fixed Gaussian | 600 | 4 | 0.0005 |
| Wald CI | fixed Gaussian | 600 | 4 | 0.0000 |
| profile CI warm | fixed Gaussian | 600 | 4 | 0.0135 |
| bootstrap CI B=20 serial | fixed Gaussian | 600 | 4 | 0.0048 |
| bootstrap CI B=20 threaded | fixed Gaussian | 600 | 4 | 0.0017 |
| fit | crossed Gaussian | 900 | 5 | 0.1571 |
| profile CI warm | crossed Gaussian | 900 | 5 | 6.1822 |
| profile CI threaded warm | crossed Gaussian | 900 | 5 | 2.5753 |

Interpretation guardrails:
- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.
- Profile CI now warm-starts nuisance fits in the production `confint(..., method=:profile)` path.
- Threaded profile max endpoint delta versus serial warm profile CI: 0.000e+00.
- Threaded bootstrap uses independent per-replicate RNG seeds; timings are only comparable at the explicit thread count above.
