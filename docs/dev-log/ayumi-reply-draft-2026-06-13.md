# DRAFT — Ayumi issue #2 reply (2026-06-13) — HOLD for SN approval + push

> Status: engine verified green locally (REML / separate+coupled recovery / FD ≤1e-6 /
> honest boundary CI). NOT posted. Install path depends on a USER-GATED push.

---

Hi @Ayumi-495 — thank you for the careful follow-ups, and apologies for two things in my
last note: the install branch I gave you (`shannon/RELEASE-drmtmb`) **was a local branch I
hadn't pushed yet** — hence your 404 — and you're right that on `main` the univariate
separate σ-phylo block isn't reachable from either engine. Let me correct both, and give you
something that actually runs.

## The short answer to your two questions

1. **Univariate separate/uncorrelated σ-phylo block — where is it?** It's now built and
   verified in the **DRM.jl engine** (the Julia side), with three block structures —
   **separate** (your case: no mean–scale correlation), **coupled** (the old single block),
   and **asymmetric** (σ-phylo only). It is reachable today **directly from DRM.jl**, and
   through `drmTMB(..., engine = "julia")` once I push the bridge (the R-side gate that was
   blocking `sigma ~ phylo()` is now relaxed — it just isn't pushed yet). I'll give exact
   syntax below and **ping you the moment the push lands** so the `engine = "julia"` route
   installs cleanly end-to-end.

2. **50 vs 100 posterior trees.** Use **100** — but the binding constraint isn't the tree
   count, it's your convergence rate (more below).

## What's now built + verified (mapped to your tables)

- **The `+1.0` mean–scale pin / `pdHess = FALSE` / `NA-NaN gradient` failures are a
  *parameterization* artefact, and it's fixed.** The engine's native covariance
  parameterization (log-Cholesky) lets a correlation slide to ±1 exactly as an axis SD
  collapses, which is when the Hessian goes singular and the optimizer false-converges — i.e.
  precisely your `mass` (+1.0) row and your E-model NA-gradient cases. The new
  **Fisher-z / separation parameterization** (`Σ = D·R·D`, with the correlation matrix `R`
  built so it stays strictly interior and positive-definite — the multivariate generalization
  of `z = atanh(ρ)`) keeps `R` off the ±1 wall, so the variance can still collapse to ~0
  **without** dragging the correlation to a pinned, singular-Hessian boundary. This applies to
  your **bivariate D/E across-tree models too** (it's the q4 among-axis covariance), so it
  should materially lift your E convergence rate (the 17/300 + NA-gradient run) — not by
  inventing signal, but by removing a numerical trap.

- **Separate vs coupled blocks (your D vs E).** You can now choose explicitly: a **separate**
  block fixes the mean–scale phylo correlation to 0 (your D / uncorrelated labels), a
  **coupled** block estimates it (your E). Recovery is verified — coupled correctly recovers a
  true ρ = 0.5, separate recovers the two SDs — with the exact-gradient FD gate passing
  ≤1e-6.

- **REML** (your Q4), via a `method = :REML` switch (Patterson–Thompson restricted
  likelihood), end-to-end verified; it's better-conditioned at the boundary than ML, which is
  where your high-correlation morphological traits sit. (Honesty note: the scale-axis REML is
  validated against our own finite-difference REML; a cross-engine ASReml/glmmTMB benchmark
  for this exact model class doesn't exist yet, so treat the *speed* numbers as internal.)

- **Boundary-aware profile CIs.** A well-identified σ-phylo signal returns a CI that
  **excludes 0**; an absent one returns an honest **[0, ∞)** — verified directly (your `mass`
  +1 and the σ-SD → 2e-6 collapses become *reportable results* — "no identifiable scale-phylo
  signal in this trait's variance" — with an interval, not a convergence failure).

- **Missing responses.** Rows with a missing response are dropped from the likelihood while
  the **full phylogeny is kept**, so a species with some missing reps still contributes and a
  fully-missing species stays in the prior — handles your many-missing traits.

## On the across-tree percentiles (the practical route you're on)

Two quantities, two error regimes:
- The **median / central estimates** are cheap — 50 trees is already ample (MC error of a
  sample median ≈ `1.253·SD/√K`).
- The **2.5% / 97.5% endpoints** are where 50 is thin: at K = 50 each tail is set by the 2–3
  most extreme fits, so one boundary-pinned tree swings the whole interval. 100 roughly halves
  that variance — worth it for a reported 95% interval.

**But the dominant issue is your convergence rate, not the tree count.** With D at 66/300 and
E at 17/300 (+73 NA-gradient), the *effective* number of clean fits per quantity is far below
50 (for E, only a few per pair) — no tree count fixes that. So I'd suggest: (1) go to 100;
(2) filter to clean convergences (`convergence == 0 & pdHess`) and **report the effective
number of usable fits** per quantity; (3) for boundary-pinned scale terms, report
boundary-occupancy ("k/100 trees pinned → no identifiable scale-phylo signal") rather than a
percentile interval dominated by false-convergence noise; (4) optionally attach a
Maritz–Jarrett/bootstrap SE per endpoint to decide whether more trees would actually help.
And — re-running the same across-tree analysis with the **Fisher-z** parameterization above
should pull a chunk of those false-convergences into clean ones, which helps far more than
50→100.

## How to run it — from R, via `engine = "julia"`

The separate σ-phylo block is now the **default** for the Julia engine: a `phylo()` term on
both `mu` and `sigma` fits the **uncorrelated** block (no forced mean–scale correlation).

```r
# 1. drmTMB (R) — the release branch carrying the engine = "julia" σ-phylo route
remotes::install_github("itchyshin/drmTMB", ref = "shannon/RELEASE-drmtmb")
```
```bash
# 2. DRM.jl — clone it (the default branch now ships the σ-phylo location-scale engine)
git clone https://github.com/itchyshin/DRM.jl ~/DRM.jl
```
```r
# 3. point the bridge at Julia + the DRM.jl checkout, then fit
Sys.setenv(JULIA_HOME = "/path/to/julia/bin")      # your juliaup/Julia bin dir
options(drmTMB.DRM.jl.path = "~/DRM.jl")           # the clone from step 2
library(drmTMB)

fit <- drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree),
     sigma ~ phylo(1 | species, tree = tree)),      # σ-phylo as its own block
  family = gaussian(), data = dat,
  engine = "julia", REML = TRUE                      # REML; drop for ML
)
```

(The first fit precompiles DRM.jl once — give it a minute. The boundary-aware CI comes from
`confint(fit, method = "profile")`.) A note on identifiability that matches your tables: with
**one observation per species**, the σ-phylo (and even μ-phylo) variance is only weakly
identified, so a near-0 SD with an honest `[0, ∞)` CI is the correct read for traits without
detectable scale-phylo structure — exactly your `mass`/collapsing-pair rows. Where the design
identifies it (replicates, strong signal), it recovers the mean-phylo SD well; the
σ-phylo SD point estimate stays noisy in small samples (scale REs are intrinsically hard),
so lean on the profile CI, not the point value.

> POSTED 2026-06-13 to Ayumi-495/LS_ecogeographical-rules#2 (comment 4699253063), authed as
> itchyshin. Bridge round-trip + species↔tree alignment verified; σ point estimate noted as
> small-sample-noisy (1.08 vs realized 0.64) — reply leans on the profile CI accordingly.

Thanks again — your diagnostic genuinely improved the software.
