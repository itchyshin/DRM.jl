# `general_covariance_structured`: the three unmeasured families (Poisson, NB2, Gamma), plus SE

Date: 2026-08-24 · lane: DRM.jl (Hopper, isolated worktree, task scope: measurement only)
· DRM.jl commit `8d45b651` · route: `relmat(1 | id, K = K)`, `sigma ~ 1`,
`drmTMB(..., engine = "tmb")` vs `drmTMB(..., engine = "julia")` (the DRM.jl
bridge) · script: `tools/parity_classc.R` · raw results:
`docs/dev-log/evidence/parity-classc.tsv`

## Why this file exists

The `general_covariance_structured` capability row claims four families —
Gaussian, Poisson, NB2, Gamma — via its `claim_boundary`. Before this task, only
Gaussian coefficient/logLik agreement had been re-verified against the current
comparator build's provenance; Poisson, NB2, and Gamma coefficient/logLik
agreement was already recorded (2026-08-16 A9 audit; commit `ee8658df`,
`2026-08-24-classc-cells.md`, already merged to `main` ahead of this worktree),
but with **no SE axis** and **no code-identified comparator build** (#473).
This closes both gaps for the three unmeasured families and adds a fixed-effect
SE comparison none of the class-(c) evidence had before.

**Finding up front: this is not new coefficient/logLik evidence.** Independently
re-running `tools/parity_classc.R` in this isolated worktree reproduced the
`ee8658df` coefficient-diff and logLik-diff values for `poisson_relmat`,
`nb2_relmat`, and `gamma_relmat` **exactly** (same seed 20260824, same fixture
generator, same installed drmTMB build — see provenance below) — e.g.
`nb2_relmat` max\|Δcoef\| = `1.63450860979353e-06` both times. What is new here:
(a) the SE axis, computed for the first time on these cells, and (b) the
code-identified comparator build these numbers are now anchored to.

## Comparator build (#473)

```
$ Rscript tools/drmtmb_provenance.R --toml
drmtmb_version = "0.7.0"
drmtmb_built = "R 4.6.0; aarch64-apple-darwin23; 2026-08-15 01:49:56 UTC; unix"
drmtmb_code_hash = "8dc7c6cd77f8d5cf8bebc9adb29a5a53900d2d320de074bde43cba8fa4e1bb7e"
```

Not reinstalled — this is the R library's pre-existing installed build. `built`
matches the 2026-08-15 install date already implied by
`2026-08-24-classc-cells.md`'s "installed drmTMB 0.7.0 / origin/main" line, so
this is the same comparator, now identified by code hash rather than only by
version string + date. (`tools/drmtmb_provenance.R` copied from
`origin/feat/drmtmb-catchup` for this one read-only diagnostic; not merged,
nothing else from that branch touched.)

## Method

Unchanged from `tools/parity_classc.R`'s existing pattern (same-target fit
through `drmTMB()`, `engine = "tmb"` vs `engine = "julia"`, `seed = 20260824`,
`tol = 1e-4` on coefficients/logLik). Added: an `se_of()` helper —
`sqrt(diag(vcov(fit)))`, matched **positionally** (this file's own existing
convention for coefficients, not `tools/parity_se.R`'s name-normalising
match) — recording `se_tmb`, `se_julia`, `max_abs_se_diff`, `max_rel_se_diff`
per cell. SE is "where obtainable": a `vcov()` failure on either side is
caught and recorded as `NA` without retracting the coefficient/logLik result
already established for that cell. None failed here.

No coefficient/logLik/SD-floor tolerance was changed. No pass/fail gate was
applied to the SE columns — per the task's own instruction not to widen
tolerances to manufacture agreement, and because `tools/parity_se.R`'s
`rtol_se = 1e-3` was calibrated for **fixed-effects-only** Gaussian/bivariate
cells, not a structured random effect on a non-Gaussian Laplace fit; reusing
that number here without justification would be the same error in the other
direction. The relative SE differences below are reported as measured.

## Results — the three families this task was scoped to measure

| cell | status | max\|Δcoef\| | \|Δlogℓ\| | max rel \|ΔSE\| | SE tmb / julia (positional) |
|---|---|---|---|---|---|
| poisson_relmat | PARITY_PASS | 2.06e-07 | 5.17e-12 | 4.65e-03 | 0.1416;0.1016 / 0.1409;0.1012 |
| nb2_relmat | PARITY_PASS | 1.63e-06 | 1.59e-10 | 6.79e-03 | 0.1693;0.1218;0.3427 / 0.1682;0.1216;0.3420 |
| gamma_relmat | PARITY_PASS | 2.97e-08 | 2.78e-11 | 4.08e-02 | 0.1859;0.0427;0.0755 / 0.1783;0.0426;0.0755 |

(`gaussian_relmat`, already evidenced, reproduced identically: max\|Δcoef\| =
1.62e-08, \|Δlogℓ\| = 1.37e-13, max rel \|ΔSE\| = 3.38e-07 — three to four
orders of magnitude tighter than any non-Gaussian cell, consistent with an
exact Gaussian Laplace marginal on both sides vs an approximate one for the
other three.)

Coefficients and logLik agree at 1e-4 with 2–6 orders of magnitude of
headroom for all three families — unchanged from the prior measurement, now
independently reproduced. SE agreement is **looser and family-graded**: sub-1%
relative for Poisson and NB2, ~4% for Gamma. This is the expected signature of
two independently-built Laplace approximations to the same non-Gaussian
marginal likelihood (TMB's AD Hessian `sdreport` vs DRM.jl's central
finite-difference Jacobian of its exact gradient, per `tools/parity_se.R`'s own
note) — not a sign either side is wrong, and not evidence of interval
coverage. No coverage claim is made; `interval_status` in the capability
registry is untouched by this file.

`beta_relmat` is unchanged: `NO_NATIVE_COMPARATOR`, drmTMB's refusal message
reproduced verbatim (see `parity-classc.tsv`). Beta is not one of the four
families this row's `claim_boundary` names, so it does not bear on the
verdict below; it remains the DRM.jl-only asymmetry the A9 audit already
banked.

## Verdict

**Per family**, against the row's claim ("Gaussian, Poisson, NB2, Gamma" all
fit on this route with `sigma ~ 1`):

| family | claim evidenced? |
|---|---|
| Gaussian | Yes — coef/logLik/SE all agree to ≤3.4e-07, now comparator-identified |
| Poisson | Yes — coef/logLik agree to 1e-4 with large headroom; SE agrees to 0.47% (informational, not gated) |
| NB2 | Yes — same, SE agrees to 0.68% |
| Gamma | Yes — same, SE agrees to 4.1% (loosest of the four, still an order of magnitude better than "disagreement") |

All four families the row claims now have live same-target coefficient and
logLik evidence, independently reproduced in this task and anchored to a
code-identified drmTMB build. This closes the specific gap named in this
task's brief (three of four families previously measured only once, not
independently reproduced or comparator-anchored).

**Row-level `experimental` → `partial`: still no**, for reasons outside this
task's scope and outside what this measurement can establish:

1. **No coverage claim.** Every other class-(c)/class-(a) evidence file in
   this repo is explicit that coefficient/logLik/SE agreement is not interval
   coverage. `general_covariance_structured`'s `claim_boundary` is about which
   *models* are admitted (`K`, `sigma ~ 1`, gated `beta`/precision `Q`/sigma
   predictors), not about coverage — but a promotion decision is not this
   task's call to make, and the coordination board (`docs/dev-log/
   coordination-board.md`, 2026-08-24) states explicitly "no capability row is
   `supported` anywhere" as a standing fence.
2. **The row's own claim boundary lists more than four-family fixed K.** It
   names `beta`, precision `Q`, and `sigma` predictors as "gated" — this
   measurement did not touch any of those; it only closes the four-family
   fixed-K, `sigma ~ 1` gap.
3. **This is one fixture per family (n_id=12, n_each=8, seed 20260824).** A
   promotion-grade claim would want more than a single seed per family, per
   this repo's own D-139 statistical discipline elsewhere (e.g. the interval
   trio, bootstrap evidence).

None of this is a defect in what was measured — it is the honest boundary of
what a single same-target measurement across three families establishes.
