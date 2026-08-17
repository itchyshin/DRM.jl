# A9 — `general_covariance_structured`: the family comparison the row asks for

Date: 2026-08-16 · lane: DRM.jl (Claude, arc-loop) · anchor: drmTMB **0.7.0**, installed (unmodified)

The capability row's `next_action` reads *"Compare current DRM.jl accepted
families with the R gate before widening."* This is that comparison. It is an
audit: nothing is widened, nothing is promoted.

## The table

`relmat(1 | g, K = K)` with `sigma ~ 1`, one family per row, both engines on
equivalent data:

| family | DRM.jl | drmTMB 0.7.0 | agree? |
|---|---|---|---|
| Gaussian | **FITS** | **FITS** | ✓ |
| Poisson | **FITS** | **FITS** | ✓ |
| NegBinomial2 | **FITS** | **FITS** | ✓ |
| Gamma | **FITS** | **FITS** | ✓ |
| **Beta** | **FITS** | **REFUSED** — *"Structured-effect syntax is planned, not implemented"* | ✗ |
| Binomial | REFUSED | REFUSED (same message) | ✓ (both absent) |

The drmTMB baseline was taken from the **system-installed, unmodified 0.7.0**,
deliberately not the local branch carrying the binomial-phylo work, so that
change cannot contaminate the row it would otherwise affect.

## Finding 1 — the row understates DRM.jl by one family

The row records DRM.jl's side as *"general-covariance path for Gaussian,
Poisson, NB2, and Gamma"*. **Beta also fits**, and does so cleanly
(`loglik = 110.122` on the audit fixture). So the registry's description of the
Julia side is one family stale.

This is the mirror image of the A4e ledger finding: there the countdown
*overstated* the work by counting things already delivered; here a row
*understates* a delivered capability. Both come from a description maintained by
hand alongside an engine that moved.

## Finding 2 — beta is the one genuine asymmetry, and it points the same way as #1048

`beta() + relmat()` fits in DRM.jl and is refused by drmTMB, with the same
*"Structured-effect syntax is planned, not implemented"* gate that refuses
`binomial()`. Note the shape of drmTMB's beta support:

- `beta() + phylo(...)` — **fits** (verified in the A5 comparator)
- `beta() + relmat(...)` — **refused**

So drmTMB's beta structured route is admitted for `phylo` (and `animal`, per the
gate's own enumeration) but not for `relmat`, while DRM.jl admits the general
covariance path for beta uniformly. That is a real, narrow difference in
*provider* coverage rather than in family coverage, and it is exactly the class
of gap [#1048](https://github.com/itchyshin/drmTMB/issues/1048) documents for
binomial.

## Finding 3 — DRM.jl's binomial refusal is a `MethodError`, not a message

DRM.jl refuses `Binomial() + relmat(1 | g, K = K)` with

```
MethodError: no method matching drm(::DrmFormula, ::Binomial; data=…, K=…)
```

i.e. the `Binomial` method signature does not accept `K` at all, so a user gets a
dispatch failure rather than an explanation. drmTMB refuses the same model with a
sentence naming what is and is not implemented. This is a small usability gap in
DRM.jl worth closing regardless of whether the capability is ever added — a
refusal should say why. Filed as a follow-up rather than fixed here, because the
right fix is bound up with whether binomial gains a structured route at all
(which, upstream, [drmTMB#1049](https://github.com/itchyshin/drmTMB/pull/1049)
now proposes for `phylo`).

## What this audit does NOT do

- **No widening.** The row's `next_action` is to compare *before* widening; this
  compares. Whether to admit beta on the bridge is a claim decision.
- **No promotion.** `general_covariance_structured` stays `experimental`.
- **`sigma ~ 1` only**, matching the row's stated boundary. Precision-`Q` and
  sigma-predictor routes were not exercised — the row already gates them.
- **Point-fit only.** No recovery or coverage evidence for any cell here.
