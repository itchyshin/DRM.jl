# DRAFT reply to Ayumi — issue #2 (for SN to review + post; posting is user-gated)

Hi @Ayumi-495 — thank you for the unusually thorough diagnostic, and for the
follow-up table. It did two things at once: it surfaced a real bug on **our** side,
and your numbers are a clean, near-textbook map of where the boundary lives. Here's
the honest sort of what's a fixable feature, what's a bug, and what's the data
speaking — plus what's now built and what to do in the meantime.

## The three buckets

**1. Fixable features — coming (and the first is built).**
- **Separate, uncorrelated `mu`/`sigma` phylo block (your Q2).** This is the headline
  fix. drmTMB currently *forces* the mean and σ phylo REs into one block, so it always
  estimates a mean–scale correlation — which your table shows pinning at **+1.0** for
  `mass` (false-conv, pdHess FALSE), while `tarsus`/`lightness` happen to sit off the
  boundary (+0.40 / −0.27) and converge. Convergence tracks *exactly* whether that
  forced correlation is at +1. The new route lets you fit the σ-phylo RE as its **own
  uncorrelated block**, so that artefactual +1 simply never enters. (Built on the Julia
  engine; exposed through drmTMB `engine = "julia"`.)
- **Asymmetric scale-phylo (your Q3)** — σ-phylo on one response only — is built in the
  same route.
- **REML for a structured/modelled σ (your Q4)** is on the path. You're right that it's
  the natural estimator here; its n−p correction also (mildly) helps borderline σ-phylo
  variances collapse less often.

**2. Bugs — fixed / being fixed.**
- **Our silent drop.** We found that the engine was *silently ignoring* a `phylo()`
  term on `sigma` in the univariate Gaussian path (it fit `sigma ~ phylo(…)`
  byte-identically to `sigma ~ 1`). That's now an explicit error, and then a real fit —
  thank you for the case that exposed it.
- The `NA/NaN gradient` hard-crashes should degrade into a clear "boundary /
  non-identified" message rather than crashing; that's the next robustness pass.

**3. Inherent boundary — the data speaking, not a failure.** This is the important one.
Your bivariate rows show the loc cor (mu1–mu2 — the *science*) well-identified
(+0.73, +0.24, −0.24, …), while the **σ1–σ2 scale cor pins at ±1 exactly when
`scale_sd_min` collapses** (0.001, 0.004, **2e-6**, …). A σ-phylo SD of 2e-6 isn't a
broken fit — it's the model correctly telling you there is **no identifiable
phylogenetic signal in that trait's variance**. Same in the univariate `mass` +1 pin.
For those traits/pairs, the right output is an honest interval that includes the
boundary, reported as a **result**, not something to engineer into convergence.

## What's coming for bucket 3 — honest boundary inference

The engine has profile-likelihood CIs and χ̄² (chi-bar-squared) mixture tests — valid
where the Wald Hessian is singular. We're wiring them onto the σ-phylo route so a
boundary-prone σ-phylo SD reports `[0, x]` and a correlation reports `[−1, +1]`
honestly, instead of false-converging. So `mass`'s +1 and your collapsing σ-SDs become
*reportable* ("no identifiable scale-phylo signal here"), with a CI, rather than a
pdHess = FALSE flag.

## What you can do right now (before the release)

- **Use across-tree percentiles** — exactly what Santi's analysis does (fit over the
  tree posterior, take 2.5–97.5% of the MLEs). That's a genuinely robust,
  boundary-aware interval, and you already have the machinery.
- Where a σ-phylo SD collapses to ~1e-3–1e-6, **report it as a result**: that trait/pair
  has no detectable phylogenetic structure in its variance. The bivariate **mu1–mu2**
  correlations (your loc cor) are the well-identified science and stand on their own.
- The pattern to lean on is Santi's: bivariate models give you well-identified anchors
  (mean–mean ρ, heritabilities) that hold the fit together while the boundary-prone
  scale terms ride along with honest wide CIs.

## One honesty note

The separate block removes a *software-imposed* artefact (the forced +1). It does **not**
manufacture a scale-phylo signal where the data lack one — `mass`/the collapsing pairs
may still report a σ-phylo variance whose CI includes 0, and that's the correct answer.
We didn't want to hand you a "fixed" model that quietly overstates what's there.

I'll follow up when the boundary CIs land. Thanks again — this genuinely sharpened both
the software and how we report these.
