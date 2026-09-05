# `biv_q4_phylo_reml` — fixture re-derived post-#484 (converged public route)

**Role:** Curie (fixtures) with Noether (engine contract). **Read-only on
`src/`, `tools/`.** No `src/` edits, no data regeneration.
**When:** 2026-08-25. **Fixture:** `test/parity/q4-reml/biv-q4-phylo-reml/`.
**Anchor:** the same data bytes as the existing fixture (`data.csv`,
`tree.newick` unchanged — verified via `git log` showing no commits to either
file since the fixture's original creation, `0578782b`).

---

## 1. Premise

`#484` (`574d0017`, landed on `feat/drmtmb-catchup` 2026-08-25) wired an
automatic warm restart into `fit_q4_reml` (`src/reml_q4.jl`): when the REML
LBFGS's first line-search step from the ML warm start fails outright (the
zero-accepted-steps stall diagnosed in
`docs/dev-log/evidence/2026-08-24-biv-q4-phylo-reml-converged.md`),
the fit now retries automatically and reports the genuinely converged
outcome. `drm(..., method = :REML)`'s public route converges on this cell for
the first time. The fixture's frozen `status.julia_converged = false` and its
`[tol]` (sized against the non-converged point) no longer describe the
runtime. This note re-measures the cell and re-derives `[tol]`.

## 2. Confirmed: the public route converges

```julia
fit = drm(form, Gaussian(); data = dat, tree = tree, method = :REML, q4_vcov = false)
```

Public defaults only (`q4_g_tol=1e-3`, `q4_iterations=300`, `q4_n_newton=40`,
no non-default kwargs): `is_converged(fit) == true`,
`loglik(fit) == -225.12955515317148`.

Engine-level check (same setup `_fit_bivariate_q4_phylo` builds, called via
`DRM.<name>`, no `src/` edit — mirrors `test_q4_reml_warm_restart.jl`):

```
rr.converged   = true
rr.g_residual  = 5.295043972175506e-4
g_tol          = 1e-3       # drm()'s default q4_g_tol
```

`g_residual < g_tol`, and this is the residual criterion itself, not just the
`converged` flag.

## 3. Constant-offset invariant

| Quantity | Value |
|---|---|
| `n_beta` (mu1+mu2+sigma1+sigma2 design widths = 2+2+1+1) | **6** |
| Predicted `(n_beta/2)*log(2*pi)` | **5.513631** |
| `TMB_reml` (`expected.toml` `fit.loglik`, drmTMB, unchanged) | −219.613986 |
| `DRM_reml` (converged, public route, this measurement) | −225.129555 |
| `TMB_reml − DRM_reml` (measured) | **5.515569** |
| Residual (predicted − measured) | **0.001938** |

Compare: the non-converged residual was `0.116`; the 2026-08-24 MANUAL
two-stage restart's residual was `0.008650`. The automatic restart lands
tighter than the manual one and ~60× tighter than the non-converged point —
**the constant-offset prediction HOLDS**, now on the fixture's own recorded
(public-route) numbers.

### Coefficients (converged public-route fit vs. `expected.toml`, drmTMB)

| Coefficient | Julia (converged) | drmTMB | `d_coef` |
|---|---|---|---|
| `mu1_x` | 0.3403221332 | 0.3402669951 | 0.0000551 |
| `mu2_x` | 0.4723184045 | 0.4722933884 | 0.0000250 |
| `mu1_(Intercept)` | 0.7289459042 | 0.7282568716 | 0.0006890 |
| `rho12_(Intercept)` | 0.0654452447 | 0.0656064094 | −0.0001612 |
| `mu2_(Intercept)` | 0.2375358970 | 0.2394886964 | −0.0019528 |
| `sigma1_(Intercept)` | −1.2972931252 | −1.2949619116 | −0.0023312 |
| `sigma2_(Intercept)` | −0.4440853035 | −0.4411961104 | **−0.0028892** |

**max \|d_coef\| = 0.0028892** (`sigma2_(Intercept)`).

`[fit].loglik` and `[coef]` in `expected.toml` are drmTMB's own reference
numbers (written by `test/parity/gen_biv_q4_phylo_reml.R` from the R fit, not
from Julia). A fresh drmTMB refit on the exact committed `data.csv`/
`tree.newick` (§5) reproduced them bit-for-bit
(`logLik = -219.614`, coefficients identical to 8 decimal places) — same
deterministic R fit on unchanged data, so **no edit needed** to `[fit]` or
`[coef]`. Only `status.julia_converged` and `[tol]` change.

## 4. `[tol]` re-derivation — a priori basis, not the observed gap

The instruction was to derive each tolerance from an a priori basis (as
`#483`'s reseed did — a fraction of a Wald SE from drmTMB's own fit, decided
before reading off the residual) rather than tighten until the check passes.

### `atol_loglik` = 5.5436

The test compares DRM.jl's **unnormalised** `reml_loglik` directly against
drmTMB's **normalised** one (`rtol = 0.0` hard-coded in the test), so the
tolerance must cover the known, fit-independent integration-constant offset
documented in `reml_q4.jl`, plus numerical slack:

```
atol_loglik = (n_beta/2)*log(2*pi)  +  0.03
            = 5.513631              +  0.03
            = 5.5436
```

- The offset term (5.513631) is a mathematical fact given `n_beta = 6` — it
  does not depend on any specific fit and was documented in `reml_q4.jl`
  before this measurement.
- The `0.03` slack is the cross-optimum `reml_ll` spread this exact cell's
  FD-gradient optimizer showed across independently g-converged restarts,
  documented in `docs/dev-log/evidence/2026-08-24-biv-q4-phylo-reml-converged.md`
  §3 ("further restarts ... varied reml_ll by roughly ±0.03") — established
  the day before this re-measurement, from a different restart trajectory
  than today's automatic one.

Measured residual today (0.001938) uses ~6% of that slack budget — comfortable
margin (`5.515569` vs bound `5.5436`), not razor-thin.

### `atol_coef` = 0.0251, `rtol_coef` = 0.10

Re-fit drmTMB on the **unchanged** `data.csv`/`tree.newick` (no regeneration
— same r_call as `expected.meta.toml`) to extract Wald SEs, independent of
DRM.jl's answer:

```
$ Rscript get_wald_se.R   (ad hoc, not committed — reads the committed fixture data)
mu1:(Intercept)     est=0.72825687  se=0.39242521
mu1:x               est=0.34026700  se=0.02966654
mu2:(Intercept)     est=0.23948870  se=0.30270138
mu2:x               est=0.47229339  se=0.05482400
sigma1:(Intercept)  est=-1.29496191 se=0.38813154
sigma2:(Intercept)  est=-0.44119611 se=0.25135158
rho12:(Intercept)   est=0.06560641  se=0.09513290
```

`logLik = -219.614` — matches `expected.toml` exactly, confirming this refit
reproduces the fixture's own reference fit rather than a different one.

Median SE across the 7 coefficients = 0.25135158 (`sigma2_(Intercept)`'s SE).
Fraction: **10%**, not `#483`'s 1% — `#483`'s parameter was recovered via
DRM.jl's exact O(p) analytic gradient (agreement to ~1e-8 there); this REML
profile is optimised via **finite-difference** gradients
(`h_inner = 5e-4` in `reml_q4.jl`'s `fg!`), a materially coarser numerical
regime, so a tighter-than-FD-precision tolerance would not be meaningful.
10% is independently consistent with the cross-optimum coefficient spread
`§3` of the 2026-08-24 note already documented (its worst coefficient,
`sigma1_(Intercept)`, differed from drmTMB by ~11% of that coefficient's own
SE, in a different restart, before today's number existed).

```
atol_coef  = 0.10 * median(SE) = 0.10 * 0.25135158 = 0.0251
rtol_coef  = 0.10
```

Applied to today's 7 `d_coef` values (§3), the tightest margin is
`sigma2_(Intercept)`: bound `max(0.0251, 0.10*0.444085) = 0.04441` vs
`d_coef = 0.002889` — a ~15× margin, consistent in scale with the loglik
margin above. No coefficient is anywhere near its bound.

## 5. Comparator provenance (#473)

```
$ Rscript tools/drmtmb_provenance.R --toml
drmtmb_version = "0.7.0"
drmtmb_built = "R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix"
drmtmb_code_hash = "8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e"
```

Unchanged from `expected.meta.toml` — drmTMB was **not** reinstalled.

## 6. Disagreement check

No re-measured number disagreed with drmTMB by more than the re-derived
`[tol]`. Margins ranged ~13×–1900× across the 7 coefficients and ~15× for
`loglik` (§3–4) — comfortably inside, not tuned to barely pass.

## Not this slice

`src/` (untouched) · `tools/` (untouched) · `.codex/agents/` ·
`test/parity/**` outside `q4-reml/biv-q4-phylo-reml/` · data regeneration ·
promoting the row · editing any drmTMB TSV · coverage · AI-REML.

---

## Superseded the same day — #477 removed the constant this derivation was built around

The tolerance derived above, **`atol_loglik = 5.5436`**, is
`(n_β/2)·log(2π) [5.513631] + 0.03 [cross-optimum spread]`. The first term exists only because DRM.jl's
bivariate REML routes reported the **unnormalised** restricted log-likelihood while drmTMB reported the
normalised one.

**That is no longer true** (#477, same day): every REML route in DRM.jl now reports the normalised form,
matching drmTMB, TMB, lme4, glmmTMB — and matching DRM.jl's own univariate REML routes, which had always
added the constant. So the offset term is gone and the tolerance is the spread alone:

```
atol_loglik   5.5436  ->  0.03      (185x tighter)
measured gap  5.515569 -> 0.001938
```

Verified 33/33 on the fixture, and independently by `test/test_q4_reml_warm_restart.jl`, whose #484
same-optimum check previously *allowed* a 5.5136 offset and now allows none.

**The derivation above is still correct as history and is left intact** — it is the record of why the
tolerance was what it was. What it should no longer be used for is re-deriving a tolerance: the a-priori
basis it argues from had a term in it that was a reporting artefact rather than a property of the two
engines.

That is the useful lesson here, and it is uncomfortable. The derivation was careful, explicitly a-priori
rather than fitted to the observed gap, and documented at length — and its largest term measured a
labelling difference in our own package. A tolerance that is 99.5% one constant is worth a second look at
the constant, not just at the derivation's rigour.
