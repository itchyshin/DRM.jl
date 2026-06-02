# Crossed sparse-Laplace autoresearch

Issue: #113, under umbrella #80

Date: 2026-06-02

CPU-aware setup: Julia threads = 1, BLAS threads = 1. The baseline and candidate
were both measured in this branch session with `julia --project=bench
bench/profile_crossed_laplace.jl`. Timings are medians from the existing
warm-started profile harness, not extrapolations.

## Candidate A: fused per-observation derivatives

The generic crossed non-Gaussian path previously evaluated value, first,
second, third, and nuisance derivatives through separate per-observation helper
calls. That repeated expensive work:

- link transforms for Binomial, NB2, Gamma, and Beta;
- `exp` and logarithms for NB2/Gamma;
- `digamma`, `trigamma`, and `polygamma(2, ...)` for Beta.

Candidate A adds fused derivative kernels used by the mode solve and exact
Laplace-gradient loops. The mathematical objective and gradients are unchanged;
the crossed exact-gradient finite-difference test remains the correctness gate.

## Measured result

| cell | family | baseline/s | fused/s | speedup |
|:-----|:-------|-----------:|--------:|--------:|
| small | Poisson | 0.0050 | 0.0050 | 1.00x |
| small | Binomial | 0.0456 | 0.0401 | 1.14x |
| small | NB2 | 0.0176 | 0.0132 | 1.33x |
| small | Gamma | 0.0270 | 0.0228 | 1.18x |
| small | Beta | 0.2231 | 0.0463 | 4.82x |
| medium | Poisson | 0.0297 | 0.0283 | 1.05x |
| medium | Binomial | 0.3871 | 0.3305 | 1.17x |
| medium | NB2 | 0.1813 | 0.1489 | 1.22x |
| medium | Gamma | 0.1703 | 0.1409 | 1.21x |
| medium | Beta | 1.5885 | 0.3370 | 4.71x |
| large | Poisson | 0.1800 | 0.1809 | 1.00x |
| large | Binomial | 1.2925 | 1.1519 | 1.12x |
| large | NB2 | 0.9525 | 0.8624 | 1.10x |
| large | Gamma | 0.6300 | 0.4815 | 1.31x |
| fixedq_large | Poisson | 0.1524 | 0.1472 | 1.04x |
| fixedq_large | Binomial | 1.9306 | 1.7591 | 1.10x |
| fixedq_large | NB2 | 0.5214 | 0.4376 | 1.19x |
| fixedq_large | Gamma | 0.7866 | 0.5791 | 1.36x |

Interpretation: keep Candidate A. It is neutral for Poisson, improves every
generic non-Gaussian family cell, and removes the clearest Beta bottleneck
without changing the exact sparse-Laplace contract.

## Paired drmTMB benchmark after Candidate A

The paired R-vs-Julia benchmark was regenerated with:

- `julia --project=bench bench/gen_crossed_family.jl`
- `julia --project=bench bench/fit_crossed_family.jl`
- `Rscript bench/R/fit_crossed_family.R`
- `Rscript bench/R/compare_crossed_family.R`

Successful paired Poisson/NB2 cells now report median R/Julia speedup 41.52x,
with range 25.53x to 175.16x. The medium NB2 cell is 175.16x faster
(`15.2040s` R median vs `0.0868s` Julia median). Coefficient, nuisance, RE-SD,
objective-parity, and convergence gates pass on successful paired cells.

drmTMB still rejects the crossed Binomial/Gamma/Beta cells used in the internal
Julia profile, so those rows remain internal engine evidence rather than
R-parity claims.

## Remaining bottlenecks

- Fixed-q NB2 remains unstable as a speed target: it improved in the family
  profile, but the paired fixture still took `1.6384s` on the Julia side. The
  next experiment should profile outer evaluations and mode iterations for this
  cell specifically.
- Beta is no longer catastrophically slow at n = 5000, but exact Beta
  derivatives are still special-function dominated. Large-Beta profiling should
  be reintroduced only after a focused large-cell budget is set.
- Poisson is effectively unchanged, which is expected because this candidate
  only touches the generic non-Gaussian path.
