# After-task — A3b: bivariate Student-t (`biv_student`)

Date: 2026-08-14 · lane: DRM.jl (Claude) · arc A3b · anchor: installed drmTMB **0.6.0**

## What shipped

`src/bivariate_student.jl` — the Julia twin of drmTMB's `biv_student()`: two
heavy-tailed responses sharing one scale mixture, with a **scatter** `rho12` and
a **shared** `nu`.

Estimated 1–1.5 days in the A3 re-scope; landed inside that.

## The parameterisation, pinned from drmTMB's own code

Not guessed — read off drmTMB's `simulate()` for this family (`R/methods.R`):

```r
shared_scale <- sqrt(nu / rchisq(n, df = nu))
y1 <- mu1 + sigma1 * z1 * shared_scale
y2 <- mu2 + sigma2 * z2 * shared_scale        # z2 correlated with z1 by rho12
```

That is exactly `Y ~ t_nu(mu, Sigma)` with **scale** matrix
`Sigma = diag(sigma) R diag(sigma)`. So:

- `sigma1`/`sigma2` are **scale** parameters, **not** marginal SDs — the marginal
  SD is `sigma * sqrt(nu/(nu-2))`. DRM.jl's univariate `Student` already used
  this convention, so the two agree.
- `rho12` is the **scatter** correlation.
- `nu` uses drmTMB's `logm2` link, `nu = 2 + exp(eta)` (confirmed at
  `methods.R:5724`), enforcing `nu > 2` and finite variance — again already
  DRM.jl's univariate convention.
- dpar **order** is `mu1, mu2, sigma1, sigma2, nu, rho12` — `nu` *before*
  `rho12`. The block layout matches, and a test pins it.

## Two structural facts carried into the docs, not just the code

**`nu` is shared by construction.** The scale mixture uses a single scalar
mixing variable, so one `nu` governs both margins; there is no per-margin
`nu1`/`nu2` under the exact density. Per-margin tail heaviness would require a
normal-variance-mixture copula and would give up the exact density entirely
(dr19). The grammar reflects this — `bf` offers one `nu`, and a `nu1` placeholder
is rejected.

**Zero correlation is not independence.** For any finite `nu` the margins remain
dependent even at `rho12 = 0`; independence appears only in the Gaussian limit.
That is a documentation obligation and it is in the docstring.

## A caveat that explicitly does NOT apply

dr19 documents an RQMC/derivative-free optimisation failure mode for
multivariate-t work. That concerns **probabilities** (rectangle integrals). This
likelihood evaluates the **density**, which is closed form, so ForwardDiff +
LBFGS is appropriate and the derivative-free workaround was correctly not
imported.

## Evidence

**Parity against drmTMB's own `biv_student()`**, same data (n = 800):

```
biv_student   PARITY_PASS   coef_diff=3.117e-06   loglik_diff=1.026e-09
```

All **7** parity fixture cells pass. Recovery: `nu` 5.64 vs a true 6.0, `rho12`
0.504 vs 0.5, all eight coefficients within 0.25 at n = 800.

**Grammar rail:** this arc changed `bf()`, so per campaign discipline
`DRM_PARITY_TESTS=1` was mandatory — **12 suites pass under it**, including
`test_bf_grammar`, both bivariate phylo/q4 structured suites, and `test_predict`.

## Grammar change — scoped so nothing else moves

`bf(; …, nu = …)` is Student-only: `nu` is **omitted entirely** from the bundle
unless supplied, so the Gaussian and lognormal `forms` are byte-identical to
before and everything reading them (`_bivariate_q4_marker`, the q4/q2 routes) is
untouched. A test asserts that.

A latent bug surfaced while wiring the fixture: `_bridge_formula` rebuilt the
bundle without `nu`, silently dropping a supplied `nu` formula. Harmless today
because drmTMB's first slice keeps `nu` constant and the default is
intercept-only — but it would have discarded a non-constant `nu` without error.
Fixed: `:nu` added to `_BRIDGE_BIVARIATE_KEYS` and threaded through.

## Boundary — matched, not exceeded

Residual-only: no random effects, no structured markers, **no REML** (rejection
tested). Per-cell missingness is handled correctly (a margin of a bivariate-t is
a univariate t with the *same* `nu`), but that behaviour is **not** parity-tested
against drmTMB and is not claimed.

## Next

A3c staged `biv_associate` (2–3 d) — and per the re-scope it should not start
without its own design pass: uncertainty propagation through frozen margins is
the hard part, and drmTMB bounds its own version heavily.
