# Crossed non-Gaussian sparse-Laplace family benchmark (#80)

Measured median speedup R/Julia across successful paired cells: 39.70x (min 17.91x, max 133.16x)

| cell | family | n | R med/s | Julia med/s | speedup | max d_beta | d nuisance | max d_SD | abs d_LL | conv R/J |
|:-----|:-------|--:|--------:|------------:|--------:|--------:|-----------:|--------:|------:|:---------|
| small         | poisson  |   1000 |    0.2240 |    0.0053 |   42.10x | 7.553e-07 |         - |    0.000 | 1.125e-07 | TRUE/TRUE |
| small         | binomial |   1000 |         - |    0.0481 |        - |         - |         - |        - |        - | FALSE/TRUE |
| small         | nb2      |   1000 |    2.1330 |    0.0160 |  133.16x | 1.321e-06 |     0.000 |    0.000 | 2.078e-10 | TRUE/TRUE |
| small         | gamma    |   1000 |         - |    0.0248 |        - |         - |         - |        - |        - | FALSE/TRUE |
| small         | beta     |   1000 |         - |    0.1456 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | poisson  |   5000 |    1.0200 |    0.0294 |   34.67x | 4.429e-07 |         - |    0.000 | 2.218e-09 | TRUE/TRUE |
| medium        | binomial |   5000 |         - |    0.3016 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | nb2      |   5000 |   15.0390 |    0.1163 |  129.34x | 8.069e-06 |     0.000 |    0.000 | 1.477e-08 | TRUE/TRUE |
| medium        | gamma    |   5000 |         - |    0.1682 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | beta     |   5000 |         - |    0.9746 |        - |         - |         - |        - |        - | FALSE/TRUE |
| fixedq_n20000 | poisson  |  20000 |    3.6875 |    0.2059 |   17.91x | 2.056e-06 |         - |    0.000 | 3.379e-07 | TRUE/TRUE |
| fixedq_n20000 | binomial |  20000 |         - |    2.0570 |        - |         - |         - |        - |        - | FALSE/TRUE |
| fixedq_n20000 | nb2      |  20000 |   66.8330 |    1.7917 |   37.30x | 1.349e-05 |     0.000 |    0.000 | 1.029e-07 | TRUE/TRUE |
| fixedq_n20000 | gamma    |  20000 |         - |    0.7267 |        - |         - |         - |        - |        - | FALSE/TRUE |

## Gates

- Every successful medium family cell Julia faster than drmTMB: PASS
- Every successful medium family cell at least 2x faster: PASS
- Coefficient and RE-SD parity on successful paired cells: PASS
- CPU-aware timing: both engines run without post-fit SE/sdreport; Julia pins BLAS to one thread.
- `|dLL|` is reported as an objective-parity diagnostic; constants may differ by family.
- All speedups above are measured from JSON result files, not extrapolated.

## R failures/time-limited cells

- `small` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `beta()`, `beta_binomial()`,
`cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.
- `small` `gamma`: warm-up failed: This formula contains unsupported model terms.
✖ The `mu` formula contains unsupported term: "|".
ℹ Non-Gaussian random effects are planned, not implemented in this family path.
ℹ The implemented non-Gaussian random-effect path is ordinary Poisson `mu`:
  unlabelled random intercepts and independent numeric slopes for
  non-zero-inflated Poisson models. Other families and parameters retain
  explicit unsupported messages until their recovery tests exist.
- `small` `beta`: warm-up failed: This formula contains unsupported model terms.
✖ The `mu` formula contains unsupported term: "|".
ℹ Non-Gaussian random effects are planned, not implemented in this family path.
ℹ The implemented non-Gaussian random-effect path is ordinary Poisson `mu`:
  unlabelled random intercepts and independent numeric slopes for
  non-zero-inflated Poisson models. Other families and parameters retain
  explicit unsupported messages until their recovery tests exist.
- `medium` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `beta()`, `beta_binomial()`,
`cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.
- `medium` `gamma`: warm-up failed: This formula contains unsupported model terms.
✖ The `mu` formula contains unsupported term: "|".
ℹ Non-Gaussian random effects are planned, not implemented in this family path.
ℹ The implemented non-Gaussian random-effect path is ordinary Poisson `mu`:
  unlabelled random intercepts and independent numeric slopes for
  non-zero-inflated Poisson models. Other families and parameters retain
  explicit unsupported messages until their recovery tests exist.
- `medium` `beta`: warm-up failed: This formula contains unsupported model terms.
✖ The `mu` formula contains unsupported term: "|".
ℹ Non-Gaussian random effects are planned, not implemented in this family path.
ℹ The implemented non-Gaussian random-effect path is ordinary Poisson `mu`:
  unlabelled random intercepts and independent numeric slopes for
  non-zero-inflated Poisson models. Other families and parameters retain
  explicit unsupported messages until their recovery tests exist.
- `fixedq_n20000` `binomial`: warm-up failed: Currently supported families are `gaussian()`, `student()`,
`lognormal()`, `Gamma(link = "log")`, `beta()`, `beta_binomial()`,
`cumulative_logit()`, `poisson(link = "log")`, `nbinom2()`,
`truncated_nbinom2()`, `biv_gaussian()`, `c(gaussian(), gaussian())`, and
`list(gaussian(), gaussian())`. Zero-inflated Poisson and NB2 models use the
same family route plus a `zi ~ ...` formula; hurdle NB2 models use
`truncated_nbinom2()` plus a `hu ~ ...` formula.
- `fixedq_n20000` `gamma`: warm-up failed: This formula contains unsupported model terms.
✖ The `mu` formula contains unsupported term: "|".
ℹ Non-Gaussian random effects are planned, not implemented in this family path.
ℹ The implemented non-Gaussian random-effect path is ordinary Poisson `mu`:
  unlabelled random intercepts and independent numeric slopes for
  non-zero-inflated Poisson models. Other families and parameters retain
  explicit unsupported messages until their recovery tests exist.

