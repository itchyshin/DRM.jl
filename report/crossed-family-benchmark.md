# Crossed non-Gaussian sparse-Laplace family benchmark (#80)

Measured median speedup R/Julia across successful paired cells: 43.24x (min 17.87x, max 161.78x)

R counterpart source: local drmTMB worktree codex/nongaussian-phylo-counterpart.

| cell | family | n | R med/s | Julia med/s | speedup | max d_beta | d nuisance | max d_SD | abs d_LL | conv R/J |
|:-----|:-------|--:|--------:|------------:|--------:|--------:|-----------:|--------:|------:|:---------|
| small         | poisson  |   1000 |    0.2160 |    0.0050 |   43.24x | 7.553e-07 |         - |    0.000 | 1.125e-07 | TRUE/TRUE |
| small         | binomial |   1000 |         - |    0.0449 |        - |         - |         - |        - |        - | FALSE/TRUE |
| small         | nb2      |   1000 |    2.1250 |    0.0132 |  161.25x | 1.321e-06 |     0.000 |    0.000 | 2.078e-10 | TRUE/TRUE |
| small         | gamma    |   1000 |    0.8330 |    0.0192 |   43.32x | 7.809e-08 |     0.000 |    0.000 | 1.578e-08 | TRUE/TRUE |
| small         | beta     |   1000 |    2.8750 |    0.0393 |   73.25x | 6.807e-07 |     0.000 |    0.000 | 1.858e-08 | TRUE/TRUE |
| medium        | poisson  |   5000 |    0.9940 |    0.0331 |   30.04x | 4.429e-07 |         - |    0.000 | 2.218e-09 | TRUE/TRUE |
| medium        | binomial |   5000 |         - |    0.2731 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | nb2      |   5000 |   14.1640 |    0.0876 |  161.78x | 8.069e-06 |     0.000 |    0.000 | 1.621e-08 | TRUE/TRUE |
| medium        | gamma    |   5000 |    4.2130 |    0.1372 |   30.71x | 2.787e-05 |     0.000 |    0.000 | 1.345e-07 | TRUE/TRUE |
| medium        | beta     |   5000 |   18.9330 |    0.2649 |   71.48x | 1.145e-06 |     0.000 |    0.000 | 1.964e-09 | TRUE/TRUE |
| fixedq_n20000 | poisson  |  20000 |    3.5400 |    0.1473 |   24.03x | 2.056e-06 |         - |    0.000 | 3.379e-07 | TRUE/TRUE |
| fixedq_n20000 | binomial |  20000 |         - |    1.9000 |        - |         - |         - |        - |        - | FALSE/TRUE |
| fixedq_n20000 | nb2      |  20000 |   66.1985 |    1.6638 |   39.79x | 1.349e-05 |     0.000 |    0.000 | 1.017e-07 | TRUE/TRUE |
| fixedq_n20000 | gamma    |  20000 |   11.2410 |    0.6291 |   17.87x | 7.618e-08 |     0.000 |    0.000 | 5.857e-10 | TRUE/TRUE |

## Gates

- Every successful medium family cell Julia faster than drmTMB: PASS
- Every successful medium family cell at least 2x faster: PASS
- Coefficient and RE-SD parity on successful paired cells: PASS
- CPU-aware timing: both engines run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- `|dLL|` is reported as an objective-parity diagnostic; constants may differ by family.
- All speedups above are measured from JSON result files, not extrapolated.

## R failures/time-limited cells

- `small` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `tweedie()`, `beta()`, `zero_one_beta()`,
`beta_binomial()`, `cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.
- `medium` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `tweedie()`, `beta()`, `zero_one_beta()`,
`beta_binomial()`, `cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.
- `fixedq_n20000` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `tweedie()`, `beta()`, `zero_one_beta()`,
`beta_binomial()`, `cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.

