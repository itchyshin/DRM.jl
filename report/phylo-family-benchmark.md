# Non-Gaussian phylo sparse-Laplace family benchmark (#80)

Measured median speedup R/Julia across successful paired phylo cells: 71.49x (min 18.46x, max 139.59x)

R counterpart source: local drmTMB worktree codex/nongaussian-phylo-counterpart.

Julia route: structured sparse-Laplace engine. Public `phylo(1 | species)` formula routing is now wired for NB2, Gamma, beta, and Julia-only Binomial; the paired speed table below covers the NB2/Gamma/beta cells with drmTMB counterparts.

| cell | family | p | n | R med/s | Julia med/s | speedup | max d_beta | d nuisance | d SD_phylo | abs d_LL | conv R/J |
|:-----|:-------|--:|--:|--------:|------------:|--------:|-----------:|-----------:|-----------:|---------:|:---------|
| small  | nb2   |   16 |   320 |    0.4860 |    0.0035 |  139.59x | 2.865e-06 |      0.000 |      0.000 | 1.309e-09 | TRUE/TRUE |
| small  | gamma |   16 |   320 |    0.1490 |    0.0072 |   20.79x | 4.458e-07 |      0.000 |      0.000 | 7.617e-11 | TRUE/TRUE |
| small  | beta  |   16 |   320 |    0.8420 |    0.0109 |   77.39x | 1.342e-07 |      0.000 |      0.000 | 2.359e-09 | TRUE/TRUE |
| medium | nb2   |   64 |  1280 |    1.8880 |    0.0229 |   82.51x | 1.141e-06 |      0.000 |      0.000 | 3.821e-09 | TRUE/TRUE |
| medium | gamma |   64 |  1280 |    0.7350 |    0.0398 |   18.46x | 5.361e-07 |      0.000 |      0.000 | 1.432e-10 | TRUE/TRUE |
| medium | beta  |   64 |  1280 |    3.3960 |    0.0518 |   65.58x | 1.138e-07 |      0.000 |      0.000 | 4.923e-10 | TRUE/TRUE |

## Gates

- Every successful medium phylo family cell Julia faster than drmTMB: PASS
- Every successful medium phylo family cell at least 2x faster: PASS
- Coefficient and phylo-SD parity on successful paired cells: PASS
- CPU-aware timing: both engines run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- `|dLL|` is reported as an objective-parity diagnostic; constants may differ by engine parameterization.
- All speedups above are measured from JSON result files, not extrapolated.

## R failures/time-limited cells

- None recorded by the R runner.
