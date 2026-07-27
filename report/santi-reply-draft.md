# DRAFT reply to Santi — Mammalian_decomposition issue #4 (for SN to review + post; posting is user-gated)

Reply target: https://github.com/Santiago-0rtega/Mammalian_decomposition/issues/4

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
mu1/mu2/sigma1/sigma2 with a residual `rho12`) and ran it live through the R→Julia
bridge. It:

- **converges** on the full q4 fit,
- **recovers the among-trait phylogenetic correlation** (the coevolution-of-means
  signal) — I demonstrated this on a simulated q4 analog, where the bridge returns the
  same fit the native engine produces, and
- returns **valid standard errors**.

So you can keep writing ordinary `drmTMB(...)` in R, add `engine = "julia"`, and get the
faster fit back in a drmTMB-shaped object — handy for the across-tree posterior sweeps,
where the per-fit cost is what bites.

**A bridge-only accessor fix.** Separately, `corpairs()` on the **bridge path** was not
surfacing the among-axis correlations — it returned the residual between-response
correlation but not the among-species coevolution correlations that your model is
actually about. That was a marshalling gap in the R↔Julia bridge **only**; it never
touched the native Julia (or native drmTMB) accessors, so your reported numbers were
never affected. It's now fixed, so the bridge surfaces the same among-axis correlations
you already get natively.

## Try it from R — install

DRM.jl is the Julia engine; you reach it from R through `drmTMB(..., engine = "julia")`.
Three pieces: the latest drmTMB, DRM.jl itself, and pointing the bridge at DRM.jl.

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
# then fit your q4 bivariate phylo location-scale model as usual, adding:
fit <- drmTMB(..., engine = "julia")
```

(If you `Pkg.add`ed DRM.jl into your default Julia environment, the path points at that
package source; if you cloned it, point at the clone.)

No rush, and no need to change anything you've already run — your native results stand.
But if the across-tree sweeps are a bottleneck, the Julia engine should make them
noticeably cheaper without leaving R. Happy to help if anything snags on setup, and
thanks again for the model that exercised this path.
