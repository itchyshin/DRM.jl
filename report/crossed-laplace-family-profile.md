# Crossed sparse-Laplace family profile

CPU-aware run: Julia threads = 1, BLAS threads = 1.
Poisson is drmTMB-comparable through the #70 paired benchmark. Binomial/NB2/Gamma/Beta here are internal Julia engine proofs; NB2/Gamma/Beta fix the nuisance parameter to isolate the crossed-Laplace mean engine.

| cell | family | n | G | H | median/s | beta1 | sd_g | sd_h | converged | nuisance |
|:-----|:-------|--:|--:|--:|---------:|------:|-----:|-----:|:----------|:---------|
| small | Poisson | 1000 | 20 | 20 | 0.0051 | 0.447 | 0.463 | 0.296 | true | none |
| small | Binomial | 1000 | 20 | 20 | 0.0156 | 0.486 | 0.399 | 0.302 | true | none |
| small | NB2 | 1000 | 20 | 20 | 0.0109 | 0.442 | 0.385 | 0.304 | true | size fixed at 3 |
| small | Gamma | 1000 | 20 | 20 | 0.0186 | 0.438 | 0.445 | 0.289 | true | shape fixed at 7 |
| small | Beta | 1000 | 20 | 20 | 0.1253 | 0.456 | 0.425 | 0.298 | true | precision fixed at 25 |
| medium | Poisson | 5000 | 50 | 50 | 0.0324 | 0.455 | 0.428 | 0.368 | true | none |
| medium | Binomial | 5000 | 50 | 50 | 0.2083 | 0.454 | 0.410 | 0.376 | true | none |
| medium | NB2 | 5000 | 50 | 50 | 0.0401 | 0.457 | 0.397 | 0.386 | true | size fixed at 3 |
| medium | Gamma | 5000 | 50 | 50 | 0.1359 | 0.447 | 0.427 | 0.369 | false | shape fixed at 7 |
| medium | Beta | 5000 | 50 | 50 | 0.5426 | 0.447 | 0.432 | 0.367 | true | precision fixed at 25 |
| large | Poisson | 20000 | 100 | 100 | 0.1882 | 0.442 | 0.414 | 0.367 | true | none |
| large | Binomial | 20000 | 100 | 100 | 0.4506 | 0.452 | 0.425 | 0.378 | true | none |
| large | NB2 | 20000 | 100 | 100 | 0.2462 | 0.450 | 0.404 | 0.379 | true | size fixed at 3 |
| large | Gamma | 20000 | 100 | 100 | 0.7065 | 0.446 | 0.407 | 0.377 | false | shape fixed at 7 |
| large | Beta | 20000 | 100 | 100 | 3.3984 | 0.451 | 0.411 | 0.375 | true | precision fixed at 25 |
| fixedq_large | Poisson | 20000 | 50 | 50 | 0.1550 | 0.450 | 0.428 | 0.334 | true | none |
| fixedq_large | Binomial | 20000 | 50 | 50 | 0.5226 | 0.452 | 0.436 | 0.337 | true | none |
| fixedq_large | NB2 | 20000 | 50 | 50 | 0.2238 | 0.453 | 0.431 | 0.349 | true | size fixed at 3 |
| fixedq_large | Gamma | 20000 | 50 | 50 | 0.6955 | 0.452 | 0.427 | 0.334 | false | shape fixed at 7 |
| fixedq_large | Beta | 20000 | 50 | 50 | 2.9395 | 0.449 | 0.428 | 0.338 | false | precision fixed at 25 |

Interpretation guardrails:
- Do not compare NB2/Gamma/Beta rows to drmTMB yet; nuisance parameters are fixed in this diagnostic.
- The fixed-q large cell is the scaling check: n grows while q stays at G+H=100.
- Timings are medians from repeated warm-started fits inside this process, not extrapolations.
