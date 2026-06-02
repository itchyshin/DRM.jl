# Crossed sparse-Laplace family profile

CPU-aware run: Julia threads = 1, BLAS threads = 1.
Poisson is drmTMB-comparable through the #70 paired benchmark. Binomial/NB2/Gamma/Beta here are internal Julia engine proofs; NB2/Gamma/Beta estimate one constant nuisance parameter in the Laplace objective with exact implicit nuisance-gradient corrections.
The crossed Hessian path is adaptive: dense factorisation for q ≤ 512, sparse CHOLMOD + Takahashi selected inverse for larger q.

| cell | family | n | G | H | median/s | beta1 | sd_g | sd_h | nuisance hat | nuisance truth | converged | nuisance |
|:-----|:-------|--:|--:|--:|---------:|------:|-----:|-----:|-------------:|---------------:|:----------|:---------|
| small | Poisson | 1000 | 20 | 20 | 0.0051 | 0.447 | 0.463 | 0.296 | - | - | true | none |
| small | Binomial | 1000 | 20 | 20 | 0.0469 | 0.486 | 0.399 | 0.302 | - | - | true | none |
| small | NB2 | 1000 | 20 | 20 | 0.0166 | 0.443 | 0.385 | 0.303 | 2.707 | 3.000 | true | size estimated |
| small | Gamma | 1000 | 20 | 20 | 0.0269 | 0.438 | 0.445 | 0.289 | 7.195 | 7.000 | true | shape estimated |
| small | Beta | 1000 | 20 | 20 | 0.2004 | 0.458 | 0.426 | 0.299 | 26.880 | 25.000 | true | precision estimated |
| medium | Poisson | 5000 | 50 | 50 | 0.0286 | 0.455 | 0.428 | 0.368 | - | - | true | none |
| medium | Binomial | 5000 | 50 | 50 | 0.3810 | 0.454 | 0.410 | 0.376 | - | - | true | none |
| medium | NB2 | 5000 | 50 | 50 | 0.1769 | 0.457 | 0.396 | 0.385 | 2.848 | 3.000 | true | size estimated |
| medium | Gamma | 5000 | 50 | 50 | 0.1695 | 0.447 | 0.427 | 0.369 | 7.163 | 7.000 | true | shape estimated |
| medium | Beta | 5000 | 50 | 50 | 1.4330 | 0.447 | 0.432 | 0.367 | 25.025 | 25.000 | true | precision estimated |
| large | Poisson | 20000 | 100 | 100 | 0.1843 | 0.442 | 0.414 | 0.367 | - | - | true | none |
| large | Binomial | 20000 | 100 | 100 | 1.2921 | 0.452 | 0.425 | 0.378 | - | - | true | none |
| large | NB2 | 20000 | 100 | 100 | 0.9637 | 0.450 | 0.404 | 0.379 | 3.014 | 3.000 | true | size estimated |
| large | Gamma | 20000 | 100 | 100 | 0.6312 | 0.446 | 0.407 | 0.377 | 6.957 | 7.000 | true | shape estimated |
| fixedq_large | Poisson | 20000 | 50 | 50 | 0.1486 | 0.450 | 0.428 | 0.334 | - | - | true | none |
| fixedq_large | Binomial | 20000 | 50 | 50 | 1.9299 | 0.452 | 0.436 | 0.337 | - | - | true | none |
| fixedq_large | NB2 | 20000 | 50 | 50 | 0.5218 | 0.453 | 0.431 | 0.349 | 3.154 | 3.000 | true | size estimated |
| fixedq_large | Gamma | 20000 | 50 | 50 | 0.7758 | 0.452 | 0.427 | 0.333 | 6.883 | 7.000 | true | shape estimated |

Interpretation guardrails:
- Do not compare NB2/Gamma/Beta rows to drmTMB from this report alone; use the paired R benchmark report for parity claims.
- The fixed-q large cell is the scaling check: n grows while q stays at G+H=100.
- Beta is skipped for n > 5000 in this quick profile because the current exact beta d3 path is dominated by polygamma cost.
- Timings are medians from repeated warm-started fits inside this process, not extrapolations.
