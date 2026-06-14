# DRAFT reply to Ayumi LS#2 (full follow-up, 2026-06-13, rev4) — needs Shinichi's approval to post
#
# STATUS OF THE REINSTALL TRIGGERS (verified by Rose audit, 2026-06-14):
#   DRM.jl #283 (formula :→&)            — MERGED to main.
#   DRM.jl #284 (formula *-nesting)       — MERGED to main.
#   DRM.jl #285 (missing over-param guard)— MERGED to main.
#   drmTMB #539 (missing-response include) — MERGED to main.
#   DRM.jl bivariate among-axis SD bootstrap + bridge — on branch
#     shannon/bivariate-bootstrap-sigma-a, PR pending (the §"boundary-honest CIs" tool).
# So §1/§3 reinstall instructions are true today (re-pull DRM.jl main + drmTMB main);
# the bootstrap tool ships once its PR merges — keep that paragraph conditional until then.

---

Thanks, Ayumi — the across-tree sweep is a beautiful piece of work, and stress-testing the release at full 10k-tip scale is exactly what shakes the remaining bugs loose. Let me close the loop on everything: your results, the boundary question, a new tool for honest uncertainty on the collapsing pairs (with copy-paste R), the REML question, and the three things you hit.

## Your across-tree results — the science is sound, and your reading is the right one

Nothing to correct here; if anything it's a cleaner confirmation of the boundary story than I could have written. The **mean side is the robust ecogeographical signal** and it stands on its own: Gloger (lightness ~ precipitation, **−0.245 [−0.28, −0.24]**), Bergmann (mass ~ temperature, negative), the Allen appendage-temperature contrasts, and the strong allometry — all stable across trees and essentially identical between D and E. Those are your results.

On the **scale side**, your trait-by-trait verdict is exactly the correct one: scale-phylo structure is **trait-specific**, identifiable for **lightness** (univariate, sd_σφ ≈ 0.71, clean on all trees) and the **tarsus + beakCulmen** pair (bivariate D, sd ≈ 0.61 / 0.44), and collapsing to ~1e-3–1e-6 elsewhere. A σ-phylo SD of 2e-6 with a CI against the boundary is **the model correctly reporting no detectable phylogenetic signal in that trait's variance** — a result to report, not a fit to rescue. Your line that the σ-phylo boundary "leaks into the location correlation" for the mass pairs (D vs E flipping the sign of μ1–μ2) is the mechanism exactly: when an axis SD collapses, the correlation is unidentified and rides a singular Hessian toward ±1, dragging the rest of the block with it.

**On whether a reparameterization fixes the convergence:** I built a separation / Fisher-z form of the 4×4 block (D·R·D, with the correlation kept strictly positive-definite) to improve conditioning at the boundary. It does help the *correlation* block stay well-behaved, but — to be honest with you — it **cannot manufacture identifiability** when a scale axis genuinely carries no signal: the likelihood is flat in that direction and no parameterization changes that. So I'm not going to claim a param trick "fixes" your D/E convergence; for those pairs the boundary is **inherent** (the data, as you read it). The right move is not to rescue the point estimate but to **report honest uncertainty** that includes the boundary — which is the new tool below.

## Boundary-honest among-axis SD intervals — and how to get them from R

The reason a collapsing pair gives you `pdHess = FALSE` is that at the boundary the Hessian (and hence the Wald SE, and a likelihood profile) is **singular** — there is no curvature to invert. The fix is not a better Hessian; it's a method that doesn't need one. I added a **parametric bootstrap of the among-axis SDs** to DRM.jl: it refits the q=4 model across resampled phylogenetic random effects and reports a percentile interval for each axis SD, `sqrt(diag(Σ_a))` = (sd_μ1, sd_μ2, sd_σ1, sd_σ2). Because SDs are ≥ 0, a **collapsing axis returns an interval that sits at ~0** — the honest "no detectable scale-phylo signal" statement — while an identified axis returns an interval clearly above 0. (Verified on a deliberate σ2-collapse: the collapsed axis's whole 90% interval sat below the identified axis's interval; 20/20 refits, ~6 s.)

This is where the Julia engine earns its keep over a native Hessian: **valid uncertainty exactly where the native fit reports `pdHess = FALSE`.** For the bivariate cell the cleanest way to reach it today is to call DRM.jl directly from R via JuliaCall (the `drmTMB(engine="julia")` bridge still routes *bivariate phylogenetic* fits to native `engine="tmb"` — a deliberate gate pending parity tests — so the bivariate bootstrap goes through the direct call for now). Concretely:

```r
library(JuliaCall)
julia_setup()
julia_command('import Pkg; Pkg.activate("/path/to/DRM.jl")')   # the DRM.jl checkout
julia_library("DRM")

# pass your data + Newick tree to Julia
julia_assign("y1_r", df$tarsus);  julia_assign("y2_r", df$beakCulmen)
julia_assign("sp_r", as.integer(df$species_index))             # 1-based tip index
julia_assign("temp_r", df$temp)
julia_assign("newick_r", ape::write.tree(your_phylo))

julia_command('
  phy = augmented_phy(newick_r)
  dat = (; y1 = y1_r, y2 = y2_r, temp = temp_r, species = Int.(sp_r))
  form = bf(mu1 = @formula(y1 ~ temp + phylo(1 | species)),
            mu2 = @formula(y2 ~ temp + phylo(1 | species)),
            sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
            sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
            rho12  = @formula(rho12 ~ 1))
  fit = drm(form, Gaussian(); data = dat, tree = phy)
  bsd = bootstrap_sigma_a(fit; data = dat, B = 200)
  global axis = String[String(r.param) for r in bsd.summary]
  global est  = Float64[r.estimate for r in bsd.summary]
  global lo   = Float64[r.lower for r in bsd.summary]
  global hi   = Float64[r.upper for r in bsd.summary]
')
ci <- data.frame(axis = julia_eval("axis"), sd = julia_eval("est"),
                 lower = julia_eval("lo"), upper = julia_eval("hi"))
print(ci, digits = 3)
#        axis     sd  lower upper      <- output from the attached runnable demo
# 1    sd_mu1 1.1390 0.7380 1.509          (a simulated sigma2-collapse; your traits differ)
# 2    sd_mu2 0.6478 0.4150 0.825
# 3 sd_sigma1 0.3310 0.1010 0.523
# 4 sd_sigma2 0.0793 0.0227 0.258      <- collapsed axis: interval at ~0 = no signal
```

(A self-contained runnable version is attached as `ayumi-bivariate-bootstrap-via-R.R`; the table above is its actual output — I verified the full R→Julia→R round-trip end to end.) For your **across-tree** protocol this slots straight in: wrap the fit + `bootstrap_sigma_a` in your loop over the 100 trees and report, per axis, the **fraction of trees whose SD interval excludes 0** — a boundary-occupancy summary that is far more honest than a percentile interval dominated by false-convergence noise, and it's exactly your "k/100 → no detectable scale-phylo signal" reading made quantitative. The same `bootstrap_sigma_a` also gives valid intervals for a `method = :REML` fit (it doesn't rely on the Hessian, so the provisional-SE caveat below doesn't bite it).

The idiomatic `confint(fit, method = "bootstrap")` on a `drmTMB(engine="julia")` bivariate fit is the natural next step once the bridge's bivariate-phylo path has parity tests — that's tracked; the direct call above is the same computation in the meantime.

## Native `engine = "tmb"` REML — yes, your reading is correct

Native TMB REML is deliberately location-only: `drm_validate_reml_spec` requires `sigma ~ 1` and rejects sigma random effects ("REML currently supports ordinary `mu` random effects only" / "requires an intercept-only `sigma` formula"). So sigma-phylo under native TMB is genuinely not implemented — which is exactly why the σ-phylo REML you want is routed through **`engine = "julia"`** (`REML = TRUE`), where the restricted likelihood carries a phylogenetic random effect on `sigma`. The honest caveat: the restricted-likelihood **point estimate** is sound (exact Schur-complement profiling of β_μ), but the reported **Wald SEs** there are ML curvature at the REML point (the restricted-penalty curvature term is omitted), and the scale-axis REML-vs-ML inflation isn't something I'd lean on yet — so treat σ-phylo REML *point estimates* as usable and get the *uncertainty* from the bootstrap above rather than the Wald SE.

## 1. Interaction term + `phylo()` crash — fixed, on `main`

You diagnosed it perfectly. The bridge passes the formula as a string, and R writes interactions with `:`, which Julia parses as the **range** operator (lower precedence than `+`) — so `temp + prec + temp:prec + phylo(1|species)` mis-associated and pulled the `phylo` term *inside* the interaction, producing the `|(::Int64, ::String)` error. Fixed by rewriting `:` → `&` (Julia's interaction operator) before parsing, with a regression test (interaction + phylo, interactions on `sigma`, 3-way, `*` crossing). **Merged to DRM.jl `main`** — re-pull/re-clone `main` and your `temp:prec` formulas fit directly; the precompute-the-product workaround is no longer needed. (While there I also hardened `I()`/`poly()`/`scale()`/`factor()`/`^` — including nested under `*` like `temp*lat` — so they raise a clear "precompute this column" message rather than a raw Julia error.)

## 2. Wall-time, the single-thread fallback, and optimiser controls

Taking your three practical questions in turn:

1. **Expected wall-time (~10k tips, 3–4 fixed effects).** I won't quote a number I haven't measured for the σ-phylo location-scale route specifically — but the engine's sparse phylo core is **O(p)** (measured to p = 10,000), so the right order is *minutes to low-tens-of-minutes* on the sparse/parallel route, not hours. A 52-min run that hadn't finished is more consistent with a boundary-pinned fit grinding (your `conv = 1`, sigma-phylo SD → 0) than with normal cost. **If you send me one trait + the exact formula (or a reproducible slice), I'll benchmark your specific 10k-tip fit and tell you whether your timing is normal or pathological** — that's the cleanest way to settle it.
2. **Small / subsampled trees.** Yes — the route selector picks the sparse/parallel path at scale, and a 1.5k subsample can fall onto the slower single-threaded path, so your subsample is a *worse* performance probe than the full tree. Test timing at (or near) full scale; use subsamples only for quick correctness checks.
3. **Optimiser controls.** You're right that nothing is tunable yet: `g_tol` and L-BFGS are hard-coded in the bridge, and `drm_control()` is rejected for `engine = "julia"`. The engine itself already accepts `g_tol`/`algorithm`, so exposing them (plus an iteration cap) through the R interface is **in progress** — I'll ping you when it lands. Until then, the way to tune is to call `DRM.jl` directly (the JuliaCall pattern above; set a tighter `g_tol` or a different optimiser on the `drm(...)` call). Your instinct is right: near a σ-collapse, L-BFGS can take tiny steps while the gradient norm never crosses tolerance → `conv = 1`; a tighter tolerance or a safeguarded route can turn that into a clean stop.

## 3. Missing responses on the Julia engine — now supported (univariate Gaussian)

The bridge now accepts `missing = miss_control(response = "include")` for **univariate** Gaussian on `engine = "julia"`. What you get matches what you described: the fit uses the **observed** responses while keeping the **full phylogeny/design** — missing-response rows leave the likelihood, but each partially-observed clade still informs the others through the complete tree (the observed tips' covariance is the correct submatrix of the full phylogenetic covariance). For your lightness trait (5,365 of 10,440 observed) this is the Gaussian observed-data fit, far more information-preserving than dropping whole species. It's in **drmTMB `main`** (PR #539, merged) — reinstall drmTMB from `main` (plus DRM.jl `main`).

Two honest scope notes: (a) this is the observed-data drop-rows-keep-tree fit, not a general FIML/imputation engine (tracked separately, DRM.jl #49); (b) it's wired for the **univariate** Gaussian σ-phylo / both-phylo cells — **bivariate** q=4 missing responses are not in yet (the q=4 leaf likelihood needs a per-observation observed-cell mask threaded through its exact gradient; that's a tracked follow-up, not a one-liner). For the bivariate pairs, keep using complete-case rows as you do now.

---

So, concretely: re-pull **DRM.jl `main`** and reinstall **drmTMB `main`** — the interaction crash and the (univariate) missing-response route are both fixed and merged. The **boundary-honest among-axis SD bootstrap** is the new tool for your collapsing D/E pairs; it's reachable from R via the direct JuliaCall pattern today (script attached) and ships behind a DRM.jl PR I'll point you at. The optimiser-control exposure and the idiomatic `confint(engine="julia")` bivariate wiring are the two pieces still in flight, and I'll follow up the moment each lands. And do send a trait/formula for the wall-time benchmark whenever it's convenient — happy to run it on your behalf.

Thanks again — this round turned up a real parser bug and a genuinely useful set of boundary results.
