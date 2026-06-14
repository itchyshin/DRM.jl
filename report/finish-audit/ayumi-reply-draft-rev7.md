# ============================================================================================
# INTERNAL NOTES — DO NOT SEND. Reply to Ayumi begins below the line ("Hi Ayumi —").
# rev7 (2026-06-14). Responds to her Comments 3 (install snags + 50/100 trees), 4 (bivariate
# across-tree results), 5 (univariate across-tree results). Needs Shinichi's approval to post.
#
# Answers her 3 OPEN questions head-on: (Q-A) correct install branch — shannon/RELEASE-drmtmb
# 404s; cite the clean DRM.jl branch shannon/sigma-phylo-tools [TO PUSH] + drmTMB bridge branch;
# (Q-B) bivariate scale-phylo is DRM.jl-direct today (bridge gates bivariate-phylo, #532);
# (Q-C) 50 trees sufficient (Shinichi + Pierre), 100 optional. Plus how-to-run (install + the
# across-tree loop) and the boundary-honest profile/bootstrap tools. Numbers verified vs
# /tmp/rdemo.txt. Does NOT claim profile is "calibrated" (small-p, confirmed irreducible).
# BRANCH NAMES marked [VERIFY] must match what actually gets pushed before sending.
# ============================================================================================

Hi Ayumi — this is a terrific round of work, and the across-tree runs (Comments with the D/E tables and the univariate A/B table) are exactly the right way to pin the boundary down. Let me (1) answer your two install questions and the 50-vs-100 trees one directly, (2) hand you the boundary-honest uncertainty tools that are now built — with copy-paste R for install **and** for the across-tree loop — and (3) react to your actual results, which are clean.

## Your three open questions, first

**1. The correct install branch.** You're right that `shannon/RELEASE-drmtmb` 404s — that was a stale ref I should not have given you; sorry for the dead end. The tools you want live in **two places**, and for your bivariate σ-phylo case the one that matters is DRM.jl:

- **DRM.jl** — the σ-phylo location-scale engine plus the new boundary-honest interval functions (`profile_sigma_a`, `bootstrap_sigma_a`) and the bivariate **missing-response** support. Install the clean branch:
  ```r
  # in Julia (JuliaCall::julia_command, or a Julia REPL):
  import Pkg
  Pkg.add(url = "https://github.com/itchyshin/DRM.jl", rev = "shannon/sigma-phylo-tools")   # [VERIFY ref]
  ```
- **drmTMB** — only needed for the *univariate* `engine = "julia"` path and the idiomatic `confint()`; the bridge branches you already found are the right family (`shannon/bridge-*`). For your **bivariate** σ-phylo pairs you don't need drmTMB at all — that route is reached from DRM.jl directly (next answer).

(Your toolchain is already fine — Julia 1.12.6 / JuliaCall 0.17.6 / DRM.jl load on your machine, which is the hard part.)

**2. Is scale-phylo reachable through the R `engine = "julia"` bridge yet?** For the **univariate** σ-phylo cases — yes (the separate/coupled σ-phylo block is on the bridge). For the **bivariate** σ-phylo pairs — **not yet through the bridge**; you read the vignette correctly. The `engine = "julia"` bridge currently gates *bivariate phylogenetic* fits (it routes them to native `engine = "tmb"`) until the bivariate-phylo path has R-scale parity tests — that work is tracked (drmTMB #532). So for your six trait pairs, the boundary-honest intervals are reached by calling **DRM.jl directly from R via JuliaCall** today; the idiomatic `confint(fit, method = "profile")` wrapper follows once the bridge parity lands. The direct call is the same computation — only the data goes in and the CI table comes back.

**3. 50 vs 100 posterior trees.** **50 is sufficient** for what you're doing — Shinichi and Pierre have shown that 50 trees is enough to stabilise a median and a 2.5–97.5% across-tree interval for this kind of summary. 100 won't hurt and gives a little extra tail stability if you want it, but there's **no need to re-run on our account** — keep your 50-tree summaries as final. (If anything, your compute is far better spent on the per-pair boundary intervals below than on more trees.)

## What's built now — boundary-honest intervals for the collapsing pairs

Quick framing, since you already live with `pdHess = FALSE`: at a variance-component boundary the Hessian of the negative log-likelihood is **singular** — an SD pinned at 0 has no curvature in its direction, so the observed information can't be inverted and the Wald SE / `vcov` / z-p come back `NaN`. That's structural, not numerical; no optimiser setting fixes it. The fix is uncertainty that **doesn't need the Hessian**. Two are now built in DRM.jl, and they're complementary:

- **`profile_sigma_a(fit)` — profile-likelihood CIs (boundary-honest; reach for this first).** For each among-axis SD it fixes that SD on a grid, re-optimises everything else, and inverts the likelihood ratio — no Hessian. The property you need: a **collapsed axis returns a lower bound of exactly 0** — the honest "no detectable scale-phylo signal" interval, which a percentile bootstrap structurally cannot produce. So your 2e-6 / 1e-3 σ-phylo SDs become *reportable* (sd ∈ [0, upper]) instead of convergence failures.
- **`bootstrap_sigma_a(fit; data, B)` — parametric bootstrap (detection + correlations).** Percentile interval per axis SD **plus the six among-axis coevolution correlations, each with a CI** — which the SD-by-SD profile doesn't give. This is the one that answers your D-vs-E sign-flip directly.

One honesty note up front, because it bears on how you *report* these: the **boundary call** (collapse vs signal, lower-bound-at-0) is the robust, verified part — that's what you need, and it's solid. The precise *interval width* on an identified σ axis I would **not** oversell as exactly calibrated at your tree sizes — among-axis SDs are genuinely hard at tens-to-low-hundreds of species, and a Monte-Carlo check I ran isn't clean enough for me to attach a coverage number honestly (it's an irreducible small-*p* effect, not a tuning bug — I checked). The bootstrap additionally has a *measured* scale-axis undercoverage (≈0.52 at nominal 0.90 in an M=60 study: ML shrinks a weak log-σ variance and the bootstrap inherits the bias). So: trust the **collapse/no-collapse call** and the **lower=0** statement; for the precise across-tree signal use the **distribution of the point estimate across trees** (exactly your median + 2.5–97.5% protocol), not a single fit's interval width.

### How to run it — install, one fit, then your across-tree loop

This is the full path, not just the model call. `df` is your data frame and `your_phylo` your `ape` tree; edit the two paths at the top. (A self-contained version that runs on a simulated tree with no data of yours — good for a first smoke-test — is attached as `ayumi-profile-bootstrap-via-R.R`.)

```r
library(JuliaCall)
julia_setup()                                              # your Julia 1.12.6 is fine
julia_command('import Pkg; Pkg.add(url="https://github.com/itchyshin/DRM.jl", rev="shannon/sigma-phylo-tools")')  # [VERIFY ref] — once only
julia_library("DRM"); julia_library("Random")

# --- one pair, one tree --------------------------------------------------------
# df needs: tarsus, beakCulmen, temp, prec, mass, and species_index (1..n_species,
# matching the tree's tip order). Pass the data + the tree (as a Newick string):
julia_assign("y1_r", df$tarsus); julia_assign("y2_r", df$beakCulmen)
julia_assign("temp_r", df$temp); julia_assign("prec_r", df$prec); julia_assign("mass_r", df$mass)
julia_assign("sp_r", as.integer(df$species_index))
julia_assign("newick_r", ape::write.tree(your_phylo))

julia_command('
  phy = augmented_phy(newick_r)
  dat = (; y1=y1_r, y2=y2_r, temp=temp_r, prec=prec_r, mass=mass_r, species=Int.(sp_r))
  # your D-model fixed effects: 1 + temp + prec + temp:prec (+ mass for appendages),
  # in BOTH mu and sigma; rho12 ~ 1. (model E would share one phylo block; see note.)
  form = bf(mu1    = @formula(y1 ~ temp + prec + temp&prec + mass + phylo(1 | species)),
            mu2    = @formula(y2 ~ temp + prec + temp&prec + mass + phylo(1 | species)),
            sigma1 = @formula(sigma1 ~ temp + prec + temp&prec + mass + phylo(1 | species)),
            sigma2 = @formula(sigma2 ~ temp + prec + temp&prec + mass + phylo(1 | species)),
            rho12  = @formula(rho12 ~ 1))
  fit = drm(form, Gaussian(); data = dat, tree = phy)       # ML; method = :REML also OK
  pr  = profile_sigma_a(fit; level = 0.95)                  # boundary-honest SD CIs (lower=0 at a collapse)
  bsd = bootstrap_sigma_a(fit; data = dat, B = 200, rng = Random.MersenneTwister(1))  # + 6 correlations
  global p_axis=String[String(r.param) for r in pr.summary];  global p_lo=Float64[r.lower for r in pr.summary]
  global p_est =Float64[r.estimate for r in pr.summary];      global p_hi=Float64[r.upper for r in pr.summary]
  global c_pair=String[String(r.param) for r in bsd.cor_summary]; global c_lo=Float64[r.lower for r in bsd.cor_summary]
  global c_est =Float64[r.estimate for r in bsd.cor_summary];     global c_hi=Float64[r.upper for r in bsd.cor_summary]
')
data.frame(axis=julia_eval("p_axis"), sd=julia_eval("p_est"),
           lower=julia_eval("p_lo"), upper=julia_eval("p_hi"))   # the σ-phylo SDs, boundary-honest
data.frame(pair=julia_eval("c_pair"), cor=julia_eval("c_est"),
           lower=julia_eval("c_lo"), upper=julia_eval("c_hi"))   # the 6 coevolution correlations
```

**For your across-tree protocol** it drops straight into your existing loop: fit + `profile_sigma_a` (+ `bootstrap_sigma_a` for the correlations) once per tree, collect the per-tree point estimates, and summarise with your median + 2.5–97.5% — same as you're doing for the MLEs, now with the boundary-honest σ-SD lower bounds and the correlation CIs alongside. On a σ2-collapse demonstration the contrast is exactly what you'd want to report:

```
axis        profile 95% CI      reading
sd_mu1     [0.885, 1.510]       identified
sd_sigma1  [0.193, 0.547]       identified
sd_sigma2  [0.000, 0.234]       COLLAPSED — lower bound exactly 0 = "no scale-phylo signal"
```
and every coevolution correlation touching the collapsed σ2 axis comes back spanning nearly all of [−1, 1] (e.g. `cor_sigma1_sigma2 = −0.64 [−0.98, 0.96]`), while `cor_mu1_mu2` (your sign-flipping mean–mean one) is identified (0.69 [0.35, 0.92]) — i.e. the model telling you, quantitatively, *which* couplings are estimable and which aren't.

## On your actual results — they hold together, and the boundary story is right

- **`mass + *` bimodality (D vs E disagree in sign, almost no convergence).** Your reading — "the σ-phylo boundary leaks into the location correlation" — is exactly the mechanism: when a σ axis SD collapses, the σ–σ correlation is unidentified and rides a singular Hessian toward ±1, and in the coupled (E) model that drags the mean–mean correlation with it. That's why D and E disagree on `mass+tarsus` / `mass+beakCulmen` and agree everywhere the σ axis is identified. The bootstrap correlation CIs above make this *reportable*: for those pairs `cor_mu1_mu2` comes back wide / sign-spanning, which is the honest "not estimable here," not two conflicting numbers.
- **σ ~ mass dispersion-allometry (+0.7 to +0.83, tight across all pairs).** This is a clean, robust result — bigger birds have more variable appendages — and it's on the *fixed-effect* σ side, well away from the boundary, so it's not affected by any of the above. Worth foregrounding.
- **σ-phylo SD identifiable only for `tarsus + beakCulmen` (D 0.61 [0.45, 0.96], E 0.44 [0.33, 0.65]); collapses ~1e-3–1e-6 elsewhere.** Agreed — and that's a *result*, not a set of failures: report the collapsed pairs as "no detectable scale-phylo signal" with a profile lower bound of 0, and `tarsus+beakCulmen` as the one pair carrying a real σ-phylo variance.
- **Mean fixed effects (Gloger −0.245 [−0.28, −0.24], Bergmann, Allen, allometry) robust across trees and D/E.** Nothing to add — these are your headline ecogeographical results and they stand on their own.
- **Convergence cost (D 66/300, E 17/300; 73 NA/NaN-gradient; a 176-min boundary fit).** This is the boundary grinding, not normal cost — a fit pinned at a collapsing σ axis takes tiny L-BFGS/nlminb steps while the gradient never crosses tolerance. Two things help: the Julia engine's σ-phylo route is far better-conditioned at the boundary (and O(p), so the per-fit cost should be minutes, not the 176-min wall you hit on TMB), and the profile interval sidesteps the convergence question entirely — it doesn't need a clean pdHess to report the boundary. If you send me one pair + the exact formula, I'll benchmark your specific 10k-tip fit on the Julia route and tell you whether the timing is normal.

## REML (your Q4)

Native TMB REML is location-only by design (it requires `sigma ~ 1`), which is why the σ-phylo REML you want is the **`engine = "julia"`, `REML = TRUE`** route (now on drmTMB `main`) — the restricted likelihood carries the phylogenetic RE on `sigma`. Honest caveat: the restricted-likelihood **point estimate** is sound, but the reported Wald SEs there are ML curvature at the REML point, so don't lean on the scale-axis REML-vs-ML SE inflation — take the *uncertainty* from the profile/bootstrap above (both refit by ML, which is robust at the boundary where REML refits themselves struggle to converge).

## The two earlier fixes, for completeness

- **Interaction + `phylo()` crash** — fixed and merged to DRM.jl `main`: the bridge now rewrites R's `:` to Julia's `&` before parsing, so `temp:prec + phylo(1|species)` no longer mis-associates. Your `temp:prec` formulas fit directly; the precompute-the-product workaround is no longer needed.
- **Missing responses** — univariate is merged to drmTMB `main` (`missing = miss_control(response = "include")`), and the **bivariate** q=4 case is now supported too (a per-cell observed mask through the leaf likelihood and its exact gradient, verified by a finite-difference gate). So your partially-observed `lightness` pairs no longer need complete-casing — it's on the `shannon/sigma-phylo-tools` branch above.

---

So, concretely: install **DRM.jl `shannon/sigma-phylo-tools`** [VERIFY ref] and the boundary-honest σ-phylo SD + correlation intervals are a JuliaCall away (script attached, drops into your 50-tree loop); **keep your 50-tree summaries as final** (Pierre and I are confident 50 suffices); and your boundary reading is correct throughout — the collapsing pairs are the data speaking, now reportable with a CI that includes 0 rather than a `pdHess = FALSE` failure. The idiomatic `confint(engine="julia")` bivariate wrapper and the optimiser-control exposure (`drm_control()`, drmTMB #540) are the two pieces still in flight; I'll ping you the moment each lands. And do send one pair + formula whenever convenient — I'd like to benchmark your exact 10k-tip fit on the Julia route.

Thanks again — this is genuinely careful work, and the boundary map you've built is the cleanest I've seen.
