# DRAFT reply to Ayumi — issue #2 (for SN to review + post; posting is user-gated)

Hi @Ayumi-495 — thank you for the unusually thorough diagnostic, and for the
follow-up table. It did two things at once: it surfaced a real bug on **our** side,
and your numbers are a clean, near-textbook map of where the boundary lives. Most of
what was "coming" in my earlier note is now **built and verified on the engine** and
is **landing in the next coordinated release** (DRM.jl 0.2.0 + a matching drmTMB
update). So here is the honest sort of what's fixed, what's still open, **the plan for
when you can run each piece**, and what you can do today.

## The three buckets — now mostly resolved

**1. Fixable features — built and verified.**
- **Separate, uncorrelated `mu`/`sigma` phylo block (your Q2).** This was the headline
  fix and it is now built. drmTMB previously *forced* the mean and σ phylo REs into one
  block, so it always estimated a mean–scale correlation — which your table shows pinning
  at **+1.0** for `mass` (false-conv, pdHess FALSE), while `tarsus`/`lightness` happen to
  sit off the boundary (+0.40 / −0.27) and converge. Convergence tracked *exactly*
  whether that forced correlation was at +1. You can now choose the σ-phylo block
  structure explicitly:
  - **separate / uncorrelated** — fit the σ-phylo RE as its own block, so the
    artefactual +1 never enters;
  - **coupled** — the old single-block mean–scale correlation, kept as an option;
  - **asymmetric** — σ-phylo on one response only (your Q3).
  (Built on the Julia engine; exposed through drmTMB `engine = "julia"`.)
- **REML for a structured/modelled σ (your Q4)** is coming, with a **glmmTMB-style
  `REML = TRUE/FALSE` switch**. You're right that it's the natural estimator here; it is
  also **well-conditioned near the boundary**, which is exactly where your
  high-correlation morphological cases live, so it should help those borderline σ-phylo
  variances collapse less often. (See the honesty note at the end — the scale-axis REML
  correction is the one piece still open.)

**2. Bugs — fixed.**
- **Our silent drop.** The engine was *silently ignoring* a `phylo()` term on `sigma` in
  the univariate Gaussian path (it fit `sigma ~ phylo(…)` byte-identically to
  `sigma ~ 1`). That is now fixed: it **errors first** if the term cannot be honoured, and
  then **really fits** the σ-phylo structure. Thank you for the case that exposed it.

**3. Inherent boundary — the data speaking, not a failure.** This is the important one,
and it is unchanged: it was never a bug. Your bivariate rows show the loc cor (mu1–mu2 —
the *science*) well-identified (+0.73, +0.24, −0.24, …), while the **σ1–σ2 scale cor
pins at ±1 exactly when `scale_sd_min` collapses** (0.001, 0.004, **2e-6**, …). A
σ-phylo SD of 2e-6 isn't a broken fit — it's the model correctly telling you there is
**no identifiable phylogenetic signal in that trait's variance**. Same in the univariate
`mass` +1 pin. For those traits/pairs, the right output is an honest interval that
includes the boundary, reported as a **result**, not something to engineer into
convergence.

## Honest boundary inference — now built and verified

The boundary-aware **profile-likelihood CIs** are built and verified — valid where the
Wald Hessian is singular. They are boundary-aware in both directions:

- a **well-identified** σ-phylo signal returns a CI that **excludes 0**;
- an **absent** signal returns an honest **[0, ∞)** (the SD against the boundary),
  rather than a false-converged point estimate with a pdHess = FALSE flag.

So `mass`'s +1 and your collapsing σ-SDs become *reportable* ("no identifiable
scale-phylo signal here"), **with a CI**, instead of a convergence failure.

## The plan — when you can run each piece

- **Now (no install needed):** the diagnosis above stands — your table is a correct
  boundary map, and the silent σ-phylo drop is fixed in our tree. And you can already
  use across-tree percentiles today (next section).
- **Next coordinated release (soon):** the separate / coupled / asymmetric σ-phylo
  blocks **and** the boundary-aware profile CIs, runnable from R via
  `drmTMB(..., engine = "julia")`. The R-side routing is the last piece merging now.
- **Following that:** **REML** with the glmmTMB-style `REML = TRUE/FALSE` switch —
  well-conditioned near the boundary (it should help your high-correlation morphological
  cases converge where ML pins at ±1). The scale-axis REML correction is the one piece
  still being finalised (see the honesty note).

## How to install it (when the release lands)

The new σ-phylo blocks and the boundary CIs run on the DRM.jl engine, reached from R
through `drmTMB(..., engine = "julia")`. When the release is out, three pieces get you
there — the latest drmTMB, DRM.jl itself, and pointing the bridge at DRM.jl. I'll ping
you on this thread the moment it's installable end-to-end:

**1. drmTMB (R, the release branch).**

```r
# install.packages("remotes")
remotes::install_github("itchyshin/drmTMB", ref = "shannon/RELEASE-drmtmb")
```

**2. DRM.jl (Julia — not yet registered, so install from GitHub).**

```julia
import Pkg
Pkg.add(url = "https://github.com/itchyshin/DRM.jl")
```

**3. Point the R→Julia bridge at DRM.jl.** The bridge needs to find both Julia and
DRM.jl. Set `JULIA_HOME` to your Julia `bin` directory, and tell drmTMB where DRM.jl is
via either an R option or the `DRM_JL_PATH` environment variable:

```r
Sys.setenv(JULIA_HOME = "/path/to/julia/bin")          # the julia binary
# either of these locates DRM.jl:
options(drmTMB.DRM.jl.path = "/path/to/DRM.jl")
# or:  Sys.setenv(DRM_JL_PATH = "/path/to/DRM.jl")

library(drmTMB)
# then fit as usual, adding engine = "julia"
fit <- drmTMB(..., engine = "julia")
```

(If you `Pkg.add`ed DRM.jl into your default Julia environment, the path points at that
package source; if you cloned it, point at the clone.)

## What you can do right now

- **Use across-tree percentiles** — exactly what Santi's analysis does (fit over the
  tree posterior, take 2.5–97.5% of the MLEs). That's a genuinely robust, boundary-aware
  interval, and you already have the machinery. It also agrees in spirit with the new
  profile CIs.
- Where a σ-phylo SD collapses to ~1e-3–1e-6, **report it as a result**: that trait/pair
  has no detectable phylogenetic structure in its variance. The bivariate **mu1–mu2**
  correlations (your loc cor) are the well-identified science and stand on their own.
- The pattern to lean on is Santi's: bivariate models give you well-identified anchors
  (mean–mean ρ, heritabilities) that hold the fit together while the boundary-prone scale
  terms ride along with honest wide CIs.

## One honesty note

The separate block removes a *software-imposed* artefact (the forced +1). It does **not**
manufacture a scale-phylo signal where the data lack one — `mass`/the collapsing pairs
may still report a σ-phylo variance whose CI includes 0, and that's the correct answer.

The one piece still open: the **scale-axis REML correction**. REML with the
`REML = TRUE/FALSE` switch is coming and is well-conditioned at the boundary, but the
correction term on the *scale* axis specifically is not yet finalised, so for now treat
REML σ-phylo numbers as provisional until that lands. I'll follow up when it does.

Thanks again — this genuinely sharpened both the software and how we report these.
