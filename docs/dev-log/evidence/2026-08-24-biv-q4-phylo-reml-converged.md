# `biv_q4_phylo_reml` — converged fit, and the constant-offset prediction test

**Role:** Noether (math/engine contract) with Curie (fixtures). **Read-only on
`src/`.** No `src/` edits, no TSV edit, no promotion.
**When:** 2026-08-24. **Fixture:** `test/parity/q4-reml/biv-q4-phylo-reml/`.
**Anchor:** the same data bytes as the existing fixture (`data.csv`, `tree.newick`
unchanged) — no regeneration, no reseed needed.

---

## 1. Premise

`ae1d4d78` (this branch, cherry-picked from `feat/drmtmb-catchup`) corrected the
fixture's `reml_restriction_note`: drmTMB's native TMB REML marginalises
`beta_sigma1`/`beta_sigma2` in addition to `beta_mu1`/`beta_mu2` for this q4 phylo
layout (`R/drmTMB.R:1122-1152`), so both engines restrict all four fixed-effect
axes and should differ only by the integration constant `(n_beta/2)*log(2*pi)`.
With `n_beta = 6` that predicts `5.5136` against the measured `d_loglik ~ -5.63`
(residual `0.116`), and the note attributed the residual to `julia_converged =
false`, not to an incoherent criterion.

This note tests that attribution: get a converged Julia fit and see whether the
residual shrinks to something explainable by optimizer precision, or stays large
(which would resurrect the "different restricted likelihoods" reading).

## 2. Reproduced: `julia_converged = false` at `drm()` defaults

```julia
fit = drm(form, Gaussian(); data = dat, tree = tree, method = :REML, q4_vcov = false)
```

`is_converged(fit) == false`, `loglik(fit) == -225.24313853493464`,
`d_loglik == -5.629152230305749` — matches the fixture's recorded `-5.63`.

**Why it fails is not "slow convergence."** A `verbose=true` trace of the
underlying `DRM.fit_q4_reml` LBFGS shows the optimizer records only `Iter 0`
(gradient norm `0.00792379`) and then stops — **zero accepted steps** past the
ML warm start. This is identical (same `phi`, same `reml_loglik` to 6 decimals)
across every combination tried:

| Knob | Values tried | Effect |
|---|---|---|
| `q4_n_newton` | 40, 80, 120 | none — identical result |
| `q4_iterations` | 300, 800 | none — identical result |
| `q4_g_tol` | 1e-3, 1e-4 | none — identical result |

None of the three knobs `drm()` exposes move the outcome, because the inner ML
warm-start (`fit_q4_sparse_tmb`, called inside `fit_q4_reml`) is itself
insensitive to these settings on this cell (it already converges well inside
its floor tolerance), and the outer REML LBFGS's first line-search step from
that fixed warm start fails outright (very likely the non-PD-Schur-complement
barrier the code comments describe) rather than converging slowly. Confirms
the prior finding ("same numbers at 300 and 800 iterations",
`docs/dev-log/plan-actual/2026-08-16-biv-q4-phylo-reml-fixture.md`) and explains
*why*: the run was never taking any steps at all, at any iteration budget.

## 3. Getting a genuinely converged fit — better starting values

`fit_q4_reml` accepts a `phi0` warm start directly (bypassing the hard-coded ML
warm-start path). A **two-stage restart** — a coarse LBFGS pass to move past the
barrier, then a normal pass at the same default tolerance — reaches a real
optimum:

```julia
r1 = DRM.fit_q4_reml(prob, Q_cond; beta0 = β0, Lambda0 = Λ0,
                      g_tol = 1e-2, iterations = 300, n_newton = 40, lc_zero = lc_zero)
r2 = DRM.fit_q4_reml(prob, Q_cond; phi0 = r1.phi,
                      g_tol = 1e-3, iterations = 300, n_newton = 40, lc_zero = lc_zero)
r3 = DRM.fit_q4_reml(prob, Q_cond; phi0 = r2.phi,
                      g_tol = 1e-3, iterations = 1000, n_newton = 40, lc_zero = lc_zero)
```

`r3`: `converged = true`, `iterations = 3`, `g_residual = 6.30e-4` — genuinely
below the same `g_tol = 1e-3` that the single-call default is judged at
(`g_converged`, not a looser criterion smuggled in). `prob`/`Q_cond`/`β0`/`Λ0`
were built with the same setup `_fit_bivariate_q4_phylo` uses (`_design`,
`make_problem`, `_initial_scale_beta` — all called directly via `DRM.<name>`,
no `src/` edit).

**This is "better starting values," not "a looser criterion."** `q4_g_tol=1e-2`
is used only as an intermediate coarse pass to *move* the point past the
line-search barrier; the point that is reported converged is judged at the
unchanged default `g_tol = 1e-3`. A single-shot `g_tol = 1e-2` run (no restart)
does converge on its own (`iterations = 4`, `g_residual = 0.0098`) but that
*would* be reporting convergence at a loosened criterion — not used for any
number below.

**Not currently reachable through `drm()`'s public single-call API** — `phi0` is
not an exposed kwarg on `drm(f::BivariateDrmFormula, ::Gaussian; ...)`, and
wiring a restart schedule into it is a `src/` change, out of scope for this
note (`src/` is untouched — see DISCIPLINE in the driving task). So
`expected.toml`'s `status.julia_converged = false` remains an accurate
statement about the current public route and is left as `false`.

### Stability of the optimum

The REML surface near the optimum is fairly flat on this small (`p=16`) cell:
further restarts from `r3`'s point with `n_newton=80` or a tighter `g_tol=1e-4`
land on nearby points that are *also* genuinely `g_converged` (residual
`4–7e-4`) but with `reml_loglik` varying by roughly `±0.03` around `r3`'s value.
This is consistent with FD-gradient optimizer precision on a small cell, not
with multiple qualitatively different optima — every point in this cluster
gives a constant-offset residual an order of magnitude below the non-converged
case (`§4`).

## 4. Testing the prediction

| Quantity | Value |
|---|---|
| `n_beta` (`mu1` + `mu2` + `sigma1` + `sigma2` design widths = 2+2+1+1) | **6** |
| Predicted `(n_beta/2)*log(2*pi)` | **5.513631** |
| `TMB_reml` (`expected.toml` `fit.loglik`) | −219.613986 |
| `DRM_reml` (`r3`, converged) | −225.118968 |
| `TMB_reml − DRM_reml` (measured) | **5.504981** |
| **Residual** (predicted − measured) | **0.008650** |

Compare to the non-converged residual of `0.116` (13× larger). **Verdict: the
constant-offset prediction HOLDS** on a converged fit, to a residual consistent
with numerical optimizer precision on this small cell — not with a different
restricted likelihood. This overturns the original "REML parity is undefined
for this row" reading and confirms the `ae1d4d78` correction.

### Coefficients (`r3` vs. `expected.toml`)

| Coefficient | Julia (`r3`) | drmTMB | `d_coef` |
|---|---|---|---|
| `mu1_x` | 0.340230 | 0.340267 | −0.000037 |
| `mu2_x` | 0.472731 | 0.472293 | 0.000438 |
| `mu1_(Intercept)` | 0.730349 | 0.728257 | 0.002092 |
| `rho12_(Intercept)` | 0.066395 | 0.065606 | 0.000789 |
| `mu2_(Intercept)` | 0.217440 | 0.239489 | −0.022048 |
| `sigma1_(Intercept)` | −1.252472 | −1.294962 | **0.042490** |
| `sigma2_(Intercept)` | −0.464073 | −0.441196 | −0.022877 |

**max |d_coef| = 0.042490** (`sigma1_(Intercept)`) — inside the fixture's
declared `atol_coef = 0.05`.

## 5. `[tol]` — deliberately unchanged

The fixture's `[tol]` (`atol_loglik = 6.0`) still has to cover the number the
*shipped* single-call `drm()` test actually measures — the non-converged
`d_loglik ~ -5.63` — because `julia_converged` stays `false` for that route.
Re-deriving `[tol]` to the converged-fit scale (`atol_loglik` on the order of
`0.05–0.1`) only makes sense once a warm-restart schedule is wired into the
public API and the shipped test measures the converged point; that is a `src/`
change and is out of scope here. **Not applied.**

## 6. Comparator provenance (#473)

```
$ Rscript tools/drmtmb_provenance.R --toml
drmtmb_version = "0.7.0"
drmtmb_built = "R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix"
drmtmb_code_hash = "8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e"
```

Recorded in `expected.meta.toml`. drmTMB was **not** reinstalled.

## Not this slice

`src/` (untouched) · `test/parity/phylo-mean/**` (another concern owns it) ·
`.codex/agents/` · promoting the row · editing any drmTMB TSV · wiring the
warm-restart into `drm()`'s public API · `[tol]` re-derivation · coverage ·
AI-REML.
