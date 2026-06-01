# Quick inference profile

CPU-aware run: Julia threads = 4, BLAS threads = 1.

| task | fixture | n | params | elapsed/s |
|:-----|:--------|--:|-------:|----------:|
| fit | fixed Gaussian | 600 | 4 | 0.0004 |
| Wald CI | fixed Gaussian | 600 | 4 | 0.0000 |
| profile CI | fixed Gaussian | 600 | 4 | 0.0198 |
| bootstrap CI B=20 | fixed Gaussian | 600 | 4 | 0.0062 |
| fit | crossed Gaussian | 900 | 5 | 0.1521 |
| profile CI | crossed Gaussian | 900 | 5 | 8.0421 |
| profile CI warm prototype | crossed Gaussian | 900 | 5 | 5.8248 |
| profile CI threaded warm prototype | crossed Gaussian | 900 | 5 | 2.5637 |

Interpretation guardrails:
- This measures DRM.jl local costs only; it is not an R-vs-Julia comparison.
- Profile CI refits the nuisance parameters many times per coefficient, so this is the next pipeline target after bootstrap.
- Warm prototype max endpoint delta versus current profile CI: 0.000e+00.
- Threaded warm prototype max endpoint delta versus current profile CI: 0.000e+00.
- The bootstrap row is serial in this script; threaded bootstrap should be measured separately with explicit thread counts.
