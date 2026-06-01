# Crossed non-Gaussian sparse-Laplace family benchmark (#80)

Measured median speedup R/Julia across successful paired cells: 45.35x (min 34.08x, max 115.99x)

| cell | family | n | R med/s | Julia med/s | speedup | max d_beta | d nuisance | max d_SD | abs d_LL | conv R/J |
|:-----|:-------|--:|--------:|------------:|--------:|--------:|-----------:|--------:|------:|:---------|
| small         | poisson  |   1000 |    0.2190 |    0.0051 |   42.70x | 7.553e-07 |         - |    0.000 | 1.125e-07 | TRUE/TRUE |
| small         | binomial |   1000 |         - |    0.0503 |        - |         - |         - |        - |        - | FALSE/TRUE |
| small         | nb2      |   1000 |    2.1260 |    0.0186 |  114.07x | 1.321e-06 |     0.000 |    0.000 | 1.939e-10 | TRUE/TRUE |
| small         | gamma    |   1000 |         - |    0.0270 |        - |         - |         - |        - |        - | FALSE/TRUE |
| small         | beta     |   1000 |         - |    0.2747 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | poisson  |   5000 |    1.0290 |    0.0302 |   34.08x | 4.429e-07 |         - |    0.000 | 2.218e-09 | TRUE/TRUE |
| medium        | binomial |   5000 |         - |    0.3102 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | nb2      |   5000 |   15.1920 |    0.1310 |  115.99x | 7.854e-06 |     0.000 |    0.000 | 1.414e-08 | TRUE/TRUE |
| medium        | gamma    |   5000 |         - |    0.1605 |        - |         - |         - |        - |        - | FALSE/TRUE |
| medium        | beta     |   5000 |         - |    1.3643 |        - |         - |         - |        - |        - | FALSE/TRUE |
| fixedq_n20000 | poisson  |  20000 |    3.7450 |    0.2103 |   17.81x | 2.056e-06 |         - |    0.000 | 3.379e-07 | TRUE/FALSE |
| fixedq_n20000 | binomial |  20000 |         - |    2.0865 |        - |         - |         - |        - |        - | FALSE/TRUE |
| fixedq_n20000 | nb2      |  20000 |   67.9190 |    1.4977 |   45.35x | 1.329e-05 |     0.000 |    0.000 | 7.681e-08 | TRUE/TRUE |
| fixedq_n20000 | gamma    |  20000 |         - |    0.7602 |        - |         - |         - |        - |        - | FALSE/FALSE |

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

