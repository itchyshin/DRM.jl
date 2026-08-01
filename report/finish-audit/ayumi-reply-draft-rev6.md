# ============================================================================================
# INTERNAL NOTES — DO NOT SEND. The reply to Ayumi begins below the line ("Thanks, Ayumi —").
# rev6 (2026-06-14), needs Shinichi's approval to post.
#
# Framing: LEADS with profile_sigma_a as the BOUNDARY-HONEST method (returns lower=0 at a
# collapse — verified); parametric bootstrap = detection + correlation companion. Deliberately
# does NOT claim profile is "calibrated" — the profile-coverage MC was too noisy/small-p to
# support a coverage number (see profile-coverage-partial-p30.txt); that's a #287 follow-up.
# All demo numbers are the verified R->Julia->R output (ayumi-profile-bootstrap-via-R.R).
#
# MERGE-STATE (verified vs origin/main, 2026-06-14):
#   DRM.jl main:  #283 (:→&), #284 (* recursion), #285 (missing over-param guard) — MERGED.
#   drmTMB main:  #539 univariate missing — MERGED; σ-phylo REML via engine="julia" — MERGED;
#                 julia==tmb ≤1e-6 parity test — MERGED.
#   Open PRs / branches (framed in-flight): drmTMB #540 (optimizer controls), #532 (confint);
#                 DRM.jl PR #286 bootstrap_sigma_a, PR #287 profile_sigma_a; bivariate-missing
#                 is on BRANCH shannon/bivariate-missing-q4 (GitHub #19 is an unrelated ISSUE).
# ============================================================================================

Thanks, Ayumi — the across-tree sweep is a beautiful piece of work, and stress-testing the release at full 10k-tip scale is exactly what shakes the remaining bugs loose. Let me close the loop on everything: your results, the boundary question, the principled way to get honest uncertainty on the collapsing pairs (with copy-paste R), the REML question, and the three practical things you hit.

## Your across-tree results — the science is sound, and your reading is the right one

Nothing to correct here; if anything it's a cleaner confirmation of the boundary story than I could have written. The **mean side is the robust ecogeographical signal** and it stands on its own: Gloger (lightness ~ precipitation, **−0.245 [−0.28, −0.24]**), Bergmann (mass ~ temperature, negative), the Allen appendage-temperature contrasts, and the strong allometry — all stable across trees and essentially identical between D and E. Those are your results.

On the **scale side**, your trait-by-trait verdict is exactly the correct one: scale-phylo structure is **trait-specific**, identifiable for **lightness** (univariate, sd_σφ ≈ 0.71, clean on all trees) and the **tarsus + beakCulmen** pair (bivariate D, sd ≈ 0.61 / 0.44), and collapsing to ~1e-3–1e-6 elsewhere. A σ-phylo SD of 2e-6 with a CI against the boundary is **the model correctly reporting no detectable phylogenetic signal in that trait's variance** — a result to report, not a fit to rescue. Your line that the σ-phylo boundary "leaks into the location correlation" for the mass pairs (D vs E flipping the sign of μ1–μ2) is the mechanism exactly: when an axis SD collapses, the correlation is unidentified and rides a singular Hessian toward ±1, dragging the rest of the block with it.

**On whether a reparameterization fixes the convergence:** I built a separation / Fisher-z form of the 4×4 block (D·R·D, with the correlation kept strictly positive-definite) to improve conditioning at the boundary. It does help the *correlation* block stay well-behaved, but — to be honest with you — it **cannot manufacture identifiability** when a scale axis genuinely carries no signal: the likelihood is flat in that direction and no parameterization changes that. So I'm not going to claim a param trick "fixes" your D/E convergence; for those pairs the boundary is **inherent** (the data, as you read it). The right move is not to rescue the point estimate but to **report honest uncertainty that includes the boundary** — which is what the tools below do.

## `pdHess = FALSE`, and the two ways to get uncertainty without a Hessian

First, what `pdHess = FALSE` actually means, because it tells you which fixes can and can't work. TMB reports it when the Hessian of the negative log-likelihood at the optimum is **not positive-definite**. At a variance-component boundary that is not a numerical glitch — it's structural: a phylo-SD sitting at (or being dragged to) 0 is a parameter with **no curvature** in its direction, so the observed-information matrix is singular there. Everything that *inverts* that matrix is then undefined: the Wald standard errors, the `vcov`, the z/p-values — they come back `NaN`, which is exactly what you saw. A "better" Hessian or a finer optimizer cannot fix this, because there is no curvature to find. The fix is to use a method that **doesn't need the Hessian at all**. I added two to DRM.jl; they are complementary, and for your collapsing pairs you'd use both.

### 1. Profile-likelihood CIs — `profile_sigma_a` (boundary-honest; reach for this first)

This is the principled fix and the one I'd lead with. For each among-axis SD it fixes that SD at a grid of values, **re-optimizes all the other parameters** at each, and inverts the likelihood-ratio: the CI is `{ s : 2·(ℓ̂ − ℓ_profile(s)) ≤ threshold }`. No Hessian anywhere. The property that matters for your problem:

- It **respects the SD ≥ 0 boundary**: when an axis genuinely carries no signal, the profile lower bound comes back **exactly 0** — the honest "no detectable scale-phylo signal" interval. A percentile bootstrap structurally *cannot* return 0 (it resamples strictly-positive SD estimates), so this is exactly the case where profiling is the right tool, and exactly where the native Hessian gives you `pdHess = FALSE` and nothing.

Let me be straight about scope, because I'd rather under-promise: the **collapse / no-collapse call** and the **lower-bound-at-0** behaviour are the robust, verified part — that is what you need for the D/E pairs, and it's solid. The precise *width* of the interval on an identified axis I would **not** oversell as exactly calibrated at your tree sizes — among-axis SDs are genuinely hard at tens-to-low-hundreds of species, and a Monte-Carlo coverage check I ran isn't clean enough for me to attach a coverage number to it honestly yet (I'm chasing that calibration down separately). The bootstrap below has a *known, measured* miscalibration on the scale axes (≈0.52, see there); for profile I'd simply say the boundary call is trustworthy and the precise width, like any method's at small *p*, is approximate. For the precise across-tree signal, lean on the **distribution of the point estimate across trees**, not a single interval's width.

On your exact σ2-collapse case (the verified demo below), `profile_sigma_a` returns:

```
axis        sd      90% CI (profile)
sd_mu1     1.139   [0.885, 1.510]     <- identified, two-sided
sd_mu2     0.648   [0.491, 0.869]
sd_sigma1  0.331   [0.193, 0.547]
sd_sigma2  0.079   [0.000, 0.234]     <- COLLAPSED axis: lower bound exactly 0
```

That bottom row is the whole point: `sd_sigma2`'s interval runs to the boundary, which is the model's honest statement that there is "no detectable scale-phylo signal in trait 2's variance" — exactly where the native fit gives you `pdHess = FALSE` and nothing.

### 2. Parametric bootstrap — `bootstrap_sigma_a` (the detection + correlation companion)

The bootstrap refits the q=4 model across resampled phylogenetic random effects and reports a percentile interval for each axis SD **plus the six among-axis coevolution correlations, each with a CI** — which the profile (an SD-by-SD method) doesn't give you. Use it for two things: the collapse/no-collapse magnitude read, and your **correlation** question. Same demo:

```
axis        sd      90% CI (bootstrap, 195/200 converged) correlations (bootstrap 90% CI)
sd_mu1     1.139   [0.738, 1.509]      cor_mu1_mu2       0.685 [ 0.347, 0.915]  <- identified
sd_mu2     0.648   [0.415, 0.825]      cor_mu1_sigma2    0.347 [-0.971, 0.995]  <- unidentified
sd_sigma1  0.331   [0.101, 0.523]      cor_sigma1_sigma2 -0.643 [-0.983, 0.958] <- unidentified
sd_sigma2  0.079   [0.023, 0.258]      (every correlation touching the collapsed σ2 axis spans nearly all of [−1,1])
```

This is your "the σ-phylo boundary leaks into the location correlation" observation made quantitative. `cor_mu1_mu2` — the coevolution of the two trait *means*, your sign-flipping one — is **identified** (0.69 [0.35, 0.92]); but every correlation that involves the collapsed σ2 axis comes back at ~[−1, 1]. So the D-vs-E flip you saw is the model honestly telling you those couplings are **not estimable**, not two conflicting answers. The rule to report is the same as the SD one: a correlation whose CI spans the sign (and whose partner-axis SD interval reaches 0) is "no estimable coevolution signal," not a number to interpret.

### How to get both from R (verified end-to-end)

The `drmTMB(engine="julia")` bridge still routes *bivariate phylogenetic* fits to native `engine="tmb"` (a deliberate gate pending parity tests), so for the bivariate q=4 boundary-honest intervals the cleanest path today is to call DRM.jl directly from R via **JuliaCall** — the model is fit and profiled/bootstrapped entirely in Julia; only your data goes in and the CI tables come back. I ran the full R→Julia→R round-trip; the tables above are its actual output.

```r
# Template — `df` is YOUR data frame and `your_phylo` is YOUR ape tree; edit the two
# paths on the first two lines. (A self-contained version that runs with no data of
# yours is attached as ayumi-profile-bootstrap-via-R.R — start there to smoke-test.)
library(JuliaCall)
julia_setup(JULIA_HOME = "~/.julia/juliaup/julia-1.10.0+0.../bin")   # the Julia you built DRM.jl with
julia_command('import Pkg; Pkg.activate("/path/to/DRM.jl")')        # your DRM.jl checkout (see branch note below)
julia_library("DRM"); julia_library("Random")

# `df` needs columns: tarsus, beakCulmen, temp, and species_index
# (1..n_species, matching the tree's tip order). Pass them, and the tree, to Julia:
julia_assign("y1_r", df$tarsus);  julia_assign("y2_r", df$beakCulmen)
julia_assign("temp_r", df$temp);  julia_assign("sp_r", as.integer(df$species_index))
julia_assign("newick_r", ape::write.tree(your_phylo))               # your ape phylo -> Newick string

julia_command('
  phy = augmented_phy(newick_r)
  dat = (; y1 = y1_r, y2 = y2_r, temp = temp_r, species = Int.(sp_r))
  form = bf(mu1 = @formula(y1 ~ temp + phylo(1 | species)),
            mu2 = @formula(y2 ~ temp + phylo(1 | species)),
            sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
            sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
            rho12  = @formula(rho12 ~ 1))
  fit = drm(form, Gaussian(); data = dat, tree = phy)          # ML; method = :REML also OK

  pr  = profile_sigma_a(fit; level = 0.90)                     # boundary-honest SD CIs (lower=0 at a collapse)
  bsd = bootstrap_sigma_a(fit; data = dat, B = 200,
                          rng = Random.MersenneTwister(1))      # detection + 6 correlations (reproducible)
  global p_axis = String[String(r.param) for r in pr.summary]
  global p_est  = Float64[r.estimate for r in pr.summary]
  global p_lo   = Float64[r.lower for r in pr.summary]
  global p_hi   = Float64[r.upper for r in pr.summary]
')
profile_ci <- data.frame(axis = julia_eval("p_axis"), sd = julia_eval("p_est"),
                         lower = julia_eval("p_lo"), upper = julia_eval("p_hi"))
print(profile_ci, digits = 3)
```

**To run it today** you need the DRM.jl checkout on the branch that has these functions — `profile_sigma_a` (PR #287), `bootstrap_sigma_a` (PR #286), and the bivariate-missing engine work (branch `shannon/bivariate-missing-q4`). Rather than have you juggle three, I'll push a single combined branch and send you the name — then the only edits you make are the two paths at the top. Once these merge to `main` it's just `using DRM`. A self-contained runnable version of exactly this (it produced the numbers above, and uses a simulated `random_balanced_tree` so it runs with no data of yours before you swap in your traits) is attached as `ayumi-profile-bootstrap-via-R.R`. For your **across-tree** protocol it slots straight in: wrap `fit + profile_sigma_a` (and `bootstrap_sigma_a` for the correlations) in your loop over the 100 trees, and report **per quantity the distribution of the point estimate across trees** plus the per-tree interval — for the σ axes that "k/100 collapsed to the boundary" reading is exactly right, and the profile interval is the per-tree uncertainty that goes with it.

**Two honest caveats, both pushing toward your existing reading, not away from it.** (i) An among-axis SD is a *boundary* parameter (≥ 0); the discriminator between collapse and signal is **magnitude**, not a strict "excludes 0" test — a collapsed axis gives a small SD whose profile interval reaches the floor, an identified axis a clearly elevated one, and they don't overlap. (ii) **The scale-axis *bootstrap* intervals are not well-calibrated — don't read them as exact CIs.** In the MC check (M=60), the bootstrap mean-axis SD intervals are well-calibrated (≈0.88 at nominal 0.90) but the scale-axis ones severely undercover (≈0.53 / 0.52): ML shrinks the weak log-σ variance component and the bootstrap inherits the bias. That is why, for the σ-axis SDs, I'd lean on the **profile** interval's *boundary* behaviour — it can return a lower bound of exactly 0, which the percentile bootstrap structurally cannot — rather than read the bootstrap's σ-axis width as exact, and keep the bootstrap for the magnitude read and the correlations. (To be clear, I'm *not* claiming the profile *width* is better calibrated — it re-optimizes by ML around the same shrunk estimate, so it isn't obviously immune to the bias; what's solid is its boundary/lower-bound-at-0 behaviour. The precise σ-axis width is approximate for either method at small *p*.) The bootstrap undercoverage is about precise width on an *identified* σ axis; it does **not** manufacture a false signal at a truly-collapsed axis (whose interval correctly sits at/near 0).

(The idiomatic `confint(fit, method = "profile" / "bootstrap")` on a `drmTMB(engine="julia")` bivariate fit — no JuliaCall needed — is the natural next step, once the bridge's bivariate-phylo path has parity tests; that's tracked as drmTMB #532.)

## Native `engine = "tmb"` REML — yes, your reading is correct

Native TMB REML is deliberately location-only: `drm_validate_reml_spec` requires `sigma ~ 1` and rejects sigma random effects. So σ-phylo under native TMB is genuinely not implemented — which is why the σ-phylo REML you want is routed through **`engine = "julia"`** (`REML = TRUE`), now merged on drmTMB `main`, where the restricted likelihood carries a phylogenetic random effect on `sigma`. The honest caveat: the restricted-likelihood **point estimate** is sound (exact Schur-complement profiling of β_μ), but the reported **Wald SEs** there are ML curvature at the REML point, so don't lean on the scale-axis REML-vs-ML SE inflation. Get the *uncertainty* from the profile/bootstrap above instead — both refit by ML (robust at the boundary, where REML refits themselves struggle), and in practice the among-axis SD *point* estimates move very little between ML and REML, so the ML bootstrap/profile is the clean uncertainty path either way.

## 1. Interaction term + `phylo()` crash — fixed, on `main`

You diagnosed it perfectly. The bridge passes the formula as a string, and R writes interactions with `:`, which Julia parses as the **range** operator (lower precedence than `+`) — so `temp + prec + temp:prec + phylo(1|species)` mis-associated and pulled the `phylo` term *inside* the interaction, producing the `|(::Int64, ::String)` error. Fixed by rewriting `:` → `&` (Julia's interaction operator) before parsing, with a regression test (interaction + phylo, interactions on `sigma`, 3-way, `*` crossing). **Merged to DRM.jl `main`** — re-pull `main` and your `temp:prec` formulas fit directly; the precompute-the-product workaround is no longer needed. (While there I also hardened `I()`/`poly()`/`scale()`/`factor()`/`^` — including nested under `*` like `temp*lat` — so they raise a clear "precompute this column" message rather than a raw Julia error.)

## 2. Wall-time, the single-thread fallback, and optimiser controls

Taking your three practical questions in turn:

1. **Expected wall-time (~10k tips, 3–4 fixed effects).** I won't quote a number I haven't measured for the σ-phylo location-scale route specifically — but the engine's sparse phylo core is **O(p)** (measured to p = 10,000), so the right order is *minutes to low-tens-of-minutes* on the sparse/parallel route, not hours. A 52-min run that hadn't finished is more consistent with a boundary-pinned fit grinding (your `conv = 1`, σ-phylo SD → 0) than with normal cost. **If you send me one trait + the exact formula (or a reproducible slice), I'll benchmark your specific 10k-tip fit** and tell you whether your timing is normal or pathological.
2. **Small / subsampled trees.** Yes — the route selector picks the sparse/parallel path at scale, and a 1.5k subsample can fall onto the slower single-threaded path, so your subsample is a *worse* performance probe than the full tree. Test timing at (or near) full scale; use subsamples only for quick correctness checks.
3. **Optimiser controls.** You're right that nothing is tunable yet: `g_tol` and L-BFGS are hard-coded in the bridge, and `drm_control()` is rejected for `engine = "julia"`. Exposing them (`g_tol`, `algorithm`, an iteration cap) through `drm_control()` is a finished PR in review (drmTMB #540) — I'll ping you the moment it merges. Until then, tune by calling DRM.jl directly (the JuliaCall pattern above; set a tighter `g_tol` or a different optimiser on the `drm(...)` call). Your instinct is right: near a σ-collapse, L-BFGS takes tiny steps while the gradient norm never crosses tolerance → `conv = 1`; a tighter tolerance or a safeguarded route turns that into a clean stop.

## 3. Missing responses on the Julia engine — univariate merged, **bivariate now works too**

Two pieces, and the second is new since we last spoke:

- **Univariate Gaussian** (your lightness trait, 5,365 / 10,440 observed): the bridge accepts `missing = miss_control(response = "include")` on `engine = "julia"` — the fit uses the **observed** responses while keeping the **full phylogeny/design**, so each partially-observed clade still informs the others through the complete tree (the observed tips' covariance is the correct submatrix of the full phylogenetic covariance). Far more information-preserving than dropping whole species. **Merged to drmTMB `main`** (PR #539) — reinstall drmTMB `main` (plus DRM.jl `main`).
- **Bivariate q=4** (your trait *pairs*): this was the gap in my last note, and it's now closed. I threaded a per-cell observed mask through the q=4 leaf likelihood and its exact O(p) gradient, so a tip with one trait missing contributes that trait's **univariate** Gaussian marginal (the other σ and ρ correctly drop out), a tip with both missing contributes nothing but still couples through the tree prior, and an all-observed tip is bit-for-bit unchanged. It's verified by a finite-difference-vs-exact gradient gate (≤ 1e-6) **with** mixed missing cells, plus an end-to-end recovery test. So you no longer have to complete-case your bivariate pairs — partially-observed rows now enter the bivariate fit. It's on branch `shannon/bivariate-missing-q4` (in the combined branch I'll send you; a PR + the drmTMB bridge wiring follow).

(Scope note: this is the observed-data, drop-rows-keep-tree fit, not a general FIML/imputation engine — that's tracked separately, DRM.jl #49.)

---

So, concretely: re-pull **DRM.jl `main`** and reinstall **drmTMB `main`** — the interaction crash, the univariate missing-response route, and the σ-phylo REML route are all fixed and merged. For your collapsing D/E pairs, the **profile-likelihood interval** (`profile_sigma_a`) is the boundary-honest uncertainty you want — it returns a lower bound of exactly 0 on a collapsed axis, precisely where the native fit reports `pdHess = FALSE`; the **bootstrap** (`bootstrap_sigma_a`) is the companion for the magnitude read and the six coevolution correlations. Both are reachable from R via the attached JuliaCall script today and ship behind DRM.jl PRs I'll point you at. The optimiser-control exposure (drmTMB #540) and the idiomatic `confint(engine="julia")` bivariate wiring (#532) are the two pieces still in flight; I'll follow up the moment each lands. And do send a trait/formula for the wall-time benchmark whenever it's convenient — happy to run it on your behalf.

Thanks again — this round turned up a real parser bug and a genuinely useful set of boundary results.
