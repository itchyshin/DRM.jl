# #460 — live full-stack verification of profile + bootstrap CIs through `engine = "julia"`

**Date:** 2026-08-25 · **Platform:** Claude Code (Shannon) · **PR:** drmTMB#1080 (open, unmerged)

## Why this document exists

#460 is the program's headline: profile and bootstrap confidence intervals are computed by both engines
and agree natively, but drmTMB's *routing* refused them for ordinary fixed effects through
`engine = "julia"`. The fix was written and covered by `testthat`, and that is what had been reported.

**`testthat` runs against the source tree, not the installed build, and the R→Julia bridge is exactly
the layer a source-tree unit test can leave unexercised.** So "15 files, 0 failures" did not establish
that a user gets an interval. This closes that gap.

## Method

No reinstall. Reinstalling drmTMB is #473 and moves the comparator under every banked parity number at
once, so instead the branch's `R/julia-bridge.R` was sourced into a live session over the *installed*
build, and the new method called directly on a real `drmTMB_julia` fit:

```r
fit <- drmTMB(drm_formula(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia")
e <- new.env(parent = asNamespace("drmTMB"))
sys.source("julia-bridge-460.R", envir = e)          # drmTMB#1080's version
f <- get("confint.drmTMB_julia", envir = e); environment(f) <- e
f(fit, parm = "fixef:mu:x", method = "profile")
```

Data: `set.seed(11); n = 60; y = 1 + 0.5x + N(0, 0.3²)`. Environment: `DRM_JL_PATH`, `NOT_CRAN=true`,
`DRMTMB_JULIA_TESTS=true` (the live-Julia lane is gated off by default).

## Before — the installed build

```
confint(fit, parm = "fixef:mu:x", method = "profile")
Error: Unknown confidence-interval target: "fixef:mu:x".
ℹ Use full profile target names such as "fixef:mu:x".
ℹ First available targets: .
```

Worth reading twice. It **rejects the exact string it then recommends**, and its list of available
targets is empty. And `confint(fit, method = "wald")` on the same fit reports the parameter under
precisely that name — so the target was canonical all along.

## After — drmTMB#1080

| method | lower | upper | `conf.status` |
|---|---|---|---|
| wald | 0.3868388 | 0.5702478 | wald |
| **profile** | **0.3853512** | **0.5717354** | profile |
| **bootstrap** (R = 99, seed = 7) | **0.4021655** | **0.5696364** | bootstrap |

Both previously-refused methods return real intervals. The profile interval is slightly **wider** than
Wald on both sides — the expected direction when the profile likelihood is not exactly quadratic — and
the bootstrap sits in the same neighbourhood at R = 99.

## One thing this run found that the unit tests did not

Passing `B = 99` (the argument name used elsewhere in this project) is **rejected**:

> Additional arguments in `...` are not used by Julia-engine confidence intervals yet.

The replicate count on this method is `R`, matching `boot::boot`. That is a *correct* refusal — it
declines an unrecognised argument instead of silently ignoring it and returning a default-size
bootstrap, which would be the quiet-wrong-answer failure this project keeps guarding against. Recorded
because it is a real ergonomic edge a user will hit.

## What this does NOT establish

- **Not interval coverage.** Three intervals on one dataset. Agreement between engines and plausible
  interval widths are not calibration; both `interval_status != "coverage_claimed"` fences stay intact.
- **Not the installed build.** The fix is verified as *code*, sourced over the installed package. It is
  unmerged and uninstalled; #473 governs the reinstall.
- **One family, one route.** Gaussian, ordinary fixed effect, no random effects.
