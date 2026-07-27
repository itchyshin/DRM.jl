# FINAL reply to Santi — Mammalian_decomposition issue #4 (for SN to review + post; posting is user-gated)

Reply target: https://github.com/Santiago-0rtega/Mammalian_decomposition/issues/4

> Pre-post checklist (do BEFORE pasting this into the issue):
> 1. Push the drmTMB release branch to GitHub. `ref = "shannon/RELEASE-drmtmb"` is
>    a LOCAL branch — `remotes::install_github(ref = ...)` resolves against the
>    GitHub remote, so this command fails until the branch (or a tag) is pushed.
>    If you cut a tag/release instead, swap the `ref =` for that tag.
> 2. Confirm the DRM.jl GitHub repo is public (the clone step assumes it is).
> 3. Run the end-to-end q4 bridge smoke once on a real machine — the "runs
>    end-to-end" / "recovers the among-trait correlation" claims below have not
>    been reproduced live in this drafting pass.

---

Hi @Santiago-0rtega — first, thank you. This isn't a correction: nothing in your results
was wrong. Your q4 bivariate phylogenetic location–scale fits, the among-trait phylo
correlation you recovered, and the across-tree percentile intervals are all sound, and
they were a genuinely useful stress test of the engine. This is an **offer**: the same
model now runs end-to-end from R on a faster engine, and there's a small bridge fix you
might like.

## What's new for you

**Your q4 model now runs end-to-end through R via `engine = "julia"`.** I took your
bivariate phylo location–scale specification (the shared `phylo(1 | species)` marker on
mu1/mu2/sigma1/sigma2 with a residual `rho12`) and ran it through the R→Julia bridge. It:

- **converges** on the full q4 fit,
- **recovers the among-trait phylogenetic correlation** (the coevolution-of-means
  signal) — demonstrated on a simulated q4 analog, where the bridge returns the
  same fit the native engine produces, and
- returns **valid standard errors**.

So you can keep writing ordinary `drmTMB(...)` in R, add `engine = "julia"`, and get the
faster fit back in a drmTMB-shaped object — handy for the across-tree posterior sweeps,
where the per-fit cost is what bites.

**A bridge-only accessor fix.** Separately, `corpairs()` on the **bridge path** was not
surfacing the among-axis correlations — it returned the residual between-response
correlation but not the among-species coevolution correlations that your model is
actually about. That was a marshalling gap in the R↔Julia bridge **only**: the bridge now
reconstructs the 4×4 among-axis covariance from the fit and emits one row per cross-axis
pair (mean1–mean2, etc.). It never touched the native Julia (or native drmTMB) accessors,
so your reported numbers were never affected. With the fix, the bridge surfaces the same
among-axis correlations you already get natively.

## Try it from R — install

DRM.jl is the Julia engine; you reach it from R through `drmTMB(..., engine = "julia")`
(`engine = "tmb"` stays the default). Three pieces: the latest drmTMB, a local checkout of
DRM.jl, and pointing the bridge at that checkout.

**1. drmTMB (R, the release branch).**

```r
# install.packages("remotes")
remotes::install_github("itchyshin/drmTMB", ref = "shannon/RELEASE-drmtmb")
```

(If a tagged release is up by the time you read this, use `ref = "<that-tag>"` instead —
it's more stable than tracking a branch.)

**2. DRM.jl (Julia — not yet registered).** The R bridge loads DRM.jl by *activating its
source directory* (`Pkg.activate(path); using DRM`), so the simplest path is to **clone
the repo** and point the bridge at the clone:

```bash
git clone https://github.com/itchyshin/DRM.jl
```

```julia
# one-time, from Julia, inside the clone — resolve its dependencies:
import Pkg
Pkg.activate("/path/to/DRM.jl")
Pkg.instantiate()
```

**3. Point the R→Julia bridge at the DRM.jl checkout.** The bridge needs to find both
Julia and the DRM.jl source. Set `JULIA_HOME` to your Julia `bin` directory, and tell
drmTMB where the DRM.jl **directory** is via either an R option or the `DRM_JL_PATH`
environment variable:

```r
Sys.setenv(JULIA_HOME = "/path/to/julia/bin")           # the julia binary
# either of these locates the DRM.jl source directory:
options(drmTMB.DRM.jl.path = "/path/to/DRM.jl")
# or:  Sys.setenv(DRM_JL_PATH = "/path/to/DRM.jl")

library(drmTMB)
# then fit your q4 bivariate phylo location-scale model as usual, adding:
fit <- drmTMB(..., engine = "julia")
```

(The path in step 3 must be the DRM.jl **directory** you cloned in step 2 — that's the
folder the bridge activates. If you place the clone as a sibling of your R working
directory named `DRM.jl`, the bridge finds it automatically and you can skip the option /
env var.)

No rush, and no need to change anything you've already run — your native results stand.
But if the across-tree sweeps are a bottleneck, the Julia engine should make them
noticeably cheaper without leaving R. Happy to help if anything snags on setup, and
thanks again for the model that exercised this path.
