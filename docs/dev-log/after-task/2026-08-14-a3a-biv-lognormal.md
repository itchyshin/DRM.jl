# After-task — A3a: bivariate lognormal (`biv_lognormal`)

Date: 2026-08-14 · lane: DRM.jl (Claude) · arc A3a of the `engine = "julia"`
catch-up campaign · anchor: installed drmTMB **0.6.0**

## What shipped

`src/bivariate_lognormal.jl` — the Julia twin of drmTMB's `biv_lognormal()`:
two positive responses that are jointly lognormal, with a **log-residual**
`rho12`.

Estimated at 0.5–1 day in the A3 re-scope; landed inside that.

## Why it is small

The likelihood is closed form. `log(Y)` is bivariate normal, so

```
log f_Y(y) = log phi_2(log y; mu, Sigma) - sum(log y)
```

and the Jacobian `- sum(log y)` is **parameter-free**. The MLE and its
covariance are therefore *identical* to the bivariate Gaussian fit on `log y`;
only the likelihood value shifts. So the route delegates to the verified
`_fit_bivariate_residual` Gaussian kernel rather than duplicating it — one
kernel, one set of guards (`RHO_GUARD`, per-cell missingness, finite seeding),
no second copy to drift.

Both identities are asserted in the tests, not assumed:
`coef(fit) == coef(gaussian_on_log)`, `vcov` likewise, and
`loglik(gaussian) - loglik(lognormal) == Jacobian`.

## Evidence

**Parity against drmTMB's own `biv_lognormal()`** on identical data (n = 500),
via `tools/parity_fixture.R`:

```
biv_lognormal   PARITY_PASS   coef_diff=9.149e-07   loglik_diff=7.390e-12
```

Recovery: estimates within 0.12 of truth on all seven parameters at n = 500;
`rho12` 0.596 vs a true 0.6.

8 Julia suites pass (bivariate lognormal, gaussian bivariate, lognormal, bridge,
bf grammar, gaussian core, simulate, aic/bic). Full suite runs in CI.

## Scale contract (carried into the docstring)

drmTMB's `biv_lognormal()` dpars are `mu1, mu2, sigma1, sigma2, rho12` with
links `identity, identity, log, log, atanh_guarded` — the identity links mean
the location parameters live on the **log-response** scale, and `rho12` is the
**log-residual** correlation, **not** the raw-scale Pearson correlation of the
two response columns. drmTMB's vignette makes that scale part of the scientific
interpretation; the DRM.jl docstring says the same.

## Boundary — matching drmTMB's first slice, not exceeding it

Residual-only: **no random effects**, no structured
(`phylo`/`relmat`/`animal`/`spatial`) markers, **no REML**. Both rejections are
explicit and tested. Strictly-positive responses are required on observed cells,
with an error that names the row and points at `Gaussian()` on pre-logged data
as the alternative when a zero is a genuine measurement.

Not claimed: interval calibration beyond a fixed-effect DGP, random effects,
missing-data support, or any general non-Gaussian bivariate capability.

## Bridge

`_bridge_family` now maps `biv_lognormal` (and `lognormal_bivariate`,
`bivariate_lognormal`) to `LogNormal()`, mirroring how `biv_gaussian` maps to
`Gaussian()` — bivariate-ness is a property of the **formula** in DRM.jl, not of
the family type. The A2a post-fit contract holds for this family: the payload
carries all five dpars at length `n`, with positive `sigma1`/`sigma2` and
`rho12` strictly inside (-1, 1).

**This is capability parity for the Julia implementation, not bridge
admission** — `engine = "julia"` does not route `biv_lognormal` at the anchor,
and admitting it is an R-side gate change belonging to the drmTMB narrow lane.

## Next

A3b `biv_student` (1–1.5 d): same scaffold, bivariate-t kernel, one shared `nu`.
Per dr19 the df is structurally shared across margins, and dr19's
RQMC/derivative-free caveat is about multivariate-t *probabilities*, not the
density this likelihood needs.
