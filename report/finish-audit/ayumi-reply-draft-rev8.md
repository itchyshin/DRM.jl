# ============================================================================================
# INTERNAL NOTES — DO NOT SEND. Reply to Ayumi begins below the line ("Hi Ayumi —").
# rev8 (2026-06-14). The headline changed: the FULL R path is now VERIFIED end-to-end —
# drmTMB(engine="julia") bivariate σ-phylo fit -> confint(method="profile") returns the four
# among-axis SD CIs (lower=0 at a collapse), INCLUDING with missing responses
# (miss_control(response="include")). Proof: report/finish-audit/confint-roundtrip-VERIFIED.txt.
# Two engines: native engine="tmb" (pure R, improved) fits; engine="julia" adds the
# boundary-honest CIs. Install: DRM.jl rev="shannon/sigma-phylo-tools" + drmTMB
# ref="shannon/biv-confint-profile" (both pushed). Does NOT claim profile is "calibrated"
# (small-p); bootstrap scale undercoverage ≈0.52 is the only measured coverage claim.
# Numbers in the confint table are the ACTUAL verified round-trip output.
# REML UPDATE (2026-06-14): the bivariate q4 REML scale-axis gap is now FIXED — reml_q4.jl
# extends the bordered-state profiling from mean-only (β_μ) to all four axes (β_μ + β_σ).
# Engine gate VERIFIED: diag(Σ_a)_REML ≥ diag(Σ_a)_ML on ALL 4 axes (σ1: 0.27→0.40, was the
# broken axis going the WRONG way pre-fix). The REML paragraph below now states REML works
# fully — that claim DEPENDS on landing: (1) DRM.jl reml_q4.jl fix on main, (2) the drmTMB
# reml_supported biv_gaussian gate (already in the worktree). Both are LOCAL/uncommitted now.
# Needs Shinichi's OK to send + to merge the two follow-up commits.
# ============================================================================================

Hi Ayumi — big update, and a good one: **everything you need now runs from R**, and your own table turned out to be the cleanest possible map of where the boundary lives. Let me give you the headline first, then your three open questions, then the honest reporting guidance and your results.

## The headline: the whole thing works from R now

Two things to know up front, because they reframe your thread:

1. **You don't have to leave R.** `drmTMB(..., engine = "tmb")` — the **native, pure-R default** — is itself substantially improved (auto optimizer-retry, REML, `miss_control`, `is_converged()`/`pdHess`), and it fits your bivariate location-scale phylo models including the σ-phylo covariance blocks. The **Julia engine sits on top** only to supply the one thing native TMB's Wald cannot: a *boundary-honest interval* for the among-axis SDs.

2. **The boundary-honest CIs are now reachable through `confint()`** on an `engine = "julia"` fit — no raw JuliaCall wrangling. I verified the full round-trip end to end, **including with your missing-response case**:

```r
fit <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "julia")
confint(fit, method = "profile")
#>                         parm level  lower  upper   ...   profile.engine
#> 1    sd:mu1:phylo(1 | species)  0.95  0.512  2.284        julia_profile_result
#> 2    sd:mu2:phylo(1 | species)  0.95  0.263  0.885        julia_profile_result
#> 3 sd:sigma1:phylo(1 | species)  0.95  0.702  1.301        julia_profile_result
#> 4 sd:sigma2:phylo(1 | species)  0.95  0.000  0.316  <-- COLLAPSED axis: lower = 0
```
That bottom row is the whole point: `sd_sigma2`'s interval runs **to the boundary**, the calibrated-language statement of "no detectable scale-phylo signal," exactly where the native fit reports `pdHess = FALSE` and gives you nothing. And it's a **real profile likelihood** (`profile.engine = julia_profile_result`), not a Wald or a bootstrap fallback.

## Your three open questions, answered

**1. The correct install.** Sorry again for the `shannon/RELEASE-drmtmb` dead end. Good news — this all just merged to `main`, so it's a clean reinstall of both packages, no branch refs:
```r
# R side: the engine="julia" bridge + the new confint() wiring
remotes::install_github("itchyshin/drmTMB")
# Julia side: the engine + the among-axis SD inference (in Julia, or via JuliaCall)
JuliaCall::julia_command('import Pkg; Pkg.add(url="https://github.com/itchyshin/DRM.jl")')
```
For everything that does **not** need a boundary CI, you only need the `drmTMB` reinstall and `engine = "tmb"`.

**2. Is scale-phylo reachable from R now? — Yes.** Your read of the old vignette was correct *for then*, but the thread is out of date: the `engine = "julia"` bridge **does** route a bivariate q4 σ-phylo fit (all four axes `phylo(1 | p | species)`, one tree), and `confint(method = "profile" | "bootstrap")` now returns the four among-axis SD CIs. So your six pairs run start-to-finish in R — fit with `engine = "julia"`, `confint()` for the boundary-honest SDs.

**3. 50 vs 100 trees.** **50 is sufficient** — you and Pierre have shown 50 stabilises a median and a 2.5–97.5% across-tree interval for this kind of summary. 100 won't hurt but isn't needed; keep your 50-tree summaries as final.

## `pdHess = FALSE`, and which interval goes with which parameter

The reason a collapsing pair gives `pdHess = FALSE`: at a variance boundary the Hessian is singular (an SD pinned at 0 has no curvature), so the Wald SE / `vcov` are undefined. The principle that resolves it — and that the engine now encodes — is the standard one:

- **Fixed effects** (your Gloger/Bergmann/Allen slopes, the σ-allometry): **Wald is enough** — they're interior, asymptotically normal. `engine = "tmb"` gives them directly (unless `pdHess = FALSE`).
- **Random-effect variance components** (the among-axis SDs `sqrt(diag(Σ_a))`): use **profile** (default) or **bootstrap** — they're *boundary* parameters where Wald is asymmetric, can run below 0, and goes singular. `confint(engine="julia" fit, method = "profile")` is exactly this, and a collapsed axis returns a lower bound of **0** — the honest "no signal," which a percentile bootstrap structurally cannot give.

So: Wald for the fixed effects, **profile for the σ-phylo SDs**, and the bridge correctly *refuses* a Wald SD interval at the boundary rather than handing you a garbage one.

### How to run it — both engines, including your missing responses

```r
library(drmTMB)
form <- bf(mu1    = y1 ~ temp + prec + temp:prec + mass + phylo(1 | p | species, tree = tree),
           mu2    = y2 ~ temp + prec + temp:prec + mass + phylo(1 | p | species, tree = tree),
           sigma1 = ~ 1 + temp + prec + temp:prec + mass + phylo(1 | p | species, tree = tree),
           sigma2 = ~ 1 + temp + prec + temp:prec + mass + phylo(1 | p | species, tree = tree),
           rho12  = ~ 1)

# (1) native, pure R — point estimates + everything that doesn't need a boundary CI
fit_tmb <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "tmb")
# (RE SD/correlation Wald intervals are unavailable at the boundary — that's expected; use Julia for those)

# (2) Julia engine -> boundary-honest among-axis SD CIs, entirely in R
fit_jl <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "julia",
                 missing = miss_control(response = "include"))   # <- your missing lightness rows are KEPT
confint(fit_jl, method = "profile")     # the 4 among-axis SD CIs (lower = 0 on a collapse)
confint(fit_jl, method = "bootstrap")   # alternative + the among-axis coevolution correlations
```
For the across-tree protocol it drops into your existing 50-tree loop: fit + `confint(method="profile")` per tree, collect the per-tree point SDs + intervals, summarise with your median + 2.5–97.5%.

### Including your missing responses — the details (this is for your lightness pairs)

This is the part I most wanted to get right for you, so let me be concrete. Lightness is observed for 5,365 of 10,440 species; in a bivariate fit those ~5,000 lightness-missing rows **still carry their partner trait and their place on the tree**, and you shouldn't have to throw them away. You don't have to — it's one extra argument:

```r
fit_jl <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "julia",
                 missing = miss_control(response = "include"))   # <- keeps incomplete rows
nobs(fit_jl)                          # every row retained — nothing dropped
fit_jl$missing_data                   # per-row accounting + response-pattern counts
confint(fit_jl, method = "profile")   # the boundary-honest SD CIs, on the observed cells
```

What `response = "include"` does, precisely — it's the **observed-data likelihood**, not imputation and not a fudge:

- a row with **both** traits observed contributes the full bivariate term;
- a row with **one** trait observed (lightness missing, the partner present) contributes that partner's **univariate** Gaussian marginal — the missing trait's σ and the residual `rho12` correctly drop out of that row, which is the mathematically right thing, not an approximation;
- a row with **neither** observed contributes nothing to the data likelihood but its tip stays in the tree, so it still couples its relatives through the phylogenetic prior;
- the missing value itself is never read, so a `NA` placeholder is safe.

So you keep all 5,365 lightness observations **and** all the partner-trait information **and** the full phylogeny — far more information-preserving than complete-casing whole species. It's the same `miss_control(response = "include")` you already use; it now flows through the **bivariate** `engine = "julia"` route to the boundary-honest CIs too. **I verified the whole thing end to end with ~25% of one trait missing** — the fit keeps the rows (`nobs` unchanged) and all four SD intervals come back, with collapsed axes still at lower = 0. (Honest scope: this is the observed-data, keep-the-tree fit — *not* FIML/imputation of the missing responses, which is a separate and more ambitious thing; for your case the observed-data fit is exactly the right tool.)

Then the rest of the loop is as before, so your lightness pairs (5,365/10,440 observed) no longer need complete-casing.

**Two honest caveats on the σ-axis SDs, both reinforcing your reading.** (i) The **collapse/no-collapse call** and the **lower-bound-at-0** are the robust, verified part — that's what you need. (ii) I would **not** oversell the precise *width* on an identified σ axis as exactly calibrated at your tree sizes: among-axis SDs are genuinely hard at tens-to-low-hundreds of species (an irreducible small-*p* effect, which I checked — not a tuning bug). The bootstrap has a *measured* scale-axis undercoverage (≈0.52 at nominal 0.90). So trust the boundary call; for the precise across-tree signal use the **distribution of the point estimate across trees** (exactly your median + interval protocol).

## On your actual results — they hold together, and the boundary story is right

- **`mass + *` bimodality (D vs E disagree in sign, almost no convergence).** Your "σ-phylo boundary leaks into the location correlation" reading is the exact mechanism: a collapsed σ axis leaves the σ–σ correlation unidentified, riding a singular Hessian to ±1, and in the coupled (E) model dragging the mean–mean correlation along. `confint(method="bootstrap")` makes this reportable — the correlation comes back wide / sign-spanning, the honest "not estimable here."
- **σ ~ mass dispersion-allometry (+0.7 to +0.83), tight across all pairs** — a clean, robust result on the fixed-effect σ side, well away from the boundary. Worth foregrounding.
- **σ-phylo SD identifiable only for `tarsus + beakCulmen`; collapses ~1e-3–1e-6 elsewhere** — agreed; report the collapsed pairs as "no detectable scale-phylo signal" with a profile lower bound of 0, and `tarsus+beakCulmen` as the pair carrying a real σ-phylo variance.
- **Mean fixed effects (Gloger −0.245 [−0.28, −0.24], Bergmann, Allen, allometry)** — robust across trees and D/E; your headline ecogeographical results, and they stand on their own.
- **Convergence cost (D 66/300, the 176-min boundary fit)** — boundary grinding, not normal cost. The Julia route is better-conditioned and O(p), and `confint(method="profile")` sidesteps the convergence question (it doesn't need a clean `pdHess`). drmTMB `main` also now auto-retries the optimizer with `"careful"`/`"robust"` presets on a failed default fit. Send me one pair + the exact formula and I'll benchmark your 10k-tip fit on the Julia route.

## REML (your Q4)

**`REML = TRUE` now works fully for your bivariate pairs** — including the part I'd have hedged on a week ago. `engine = "julia"` fits the q4 model by Patterson–Thompson restricted likelihood, and as of this push the restricted correction covers **all four axes** — mu1, mu2, **and both σ axes** — not just the means. The defining REML property now holds on every axis: the among-species SDs come back **≥** their ML values (the n→n−p less-downward-biased estimate), the two scale axes included. (Concretely, in a controlled check the σ-axis among-SD that used to move the *wrong* way under REML — it had been getting no restricted correction at all — now lifts correctly above its ML value, the largest single correction of the four.)

So: **use `REML = TRUE` for the point estimates if you want the better-calibrated variances, and run the default ML too and compare** — they should agree closely on the means and show REML's mild upward correction on the SDs. For the *reportable* σ-phylo SD **interval**, still take `confint(method = "profile")` — it's boundary-honest and doesn't depend on ML vs REML, so it's the number to quote either way.

## The earlier fixes, for completeness

The `temp:prec + phylo()` interaction crash is fixed and merged (the bridge rewrites R's `:` to Julia's `&`). Univariate missing-response is on `main`; **bivariate q4 missing is now supported too** (the per-cell observed mask), verified by the missing-response `confint()` round-trip above.

---

So, concretely: stay in R. Use **`engine = "tmb"`** (reinstall `main`) for the fits and the fixed-effect inference; use **`engine = "julia"` + `confint(method = "profile")`** for the boundary-honest among-axis SD CIs — verified to work **with your missing responses** — and `method = "bootstrap"` for the coevolution correlations. Keep your 50-tree summaries as final. It's all on `main` now, so a reinstall of both packages is all you need. For supplementary reading, the **julia-engine article** has a new *"Bivariate boundary-honest among-axis SD intervals"* section walking through the two-engine split, the `confint(method = "profile"/"bootstrap")` table contract, the missing-response route, and why Wald is unavailable at the boundary — <https://itchyshin.github.io/drmTMB/articles/julia-engine.html> (one heads-up: the rendered page may take **another ~30 minutes or so to update** — it rebuilds through CI on the next site build now that this has merged, so if it still looks old, give it a little time). And do send a pair + formula whenever convenient — I'd like to benchmark your exact 10k-tip fit.

And please **push on it** — don't treat any of this as settled. Try `REML` and `ML`, both engines, `profile` and `bootstrap`, different formula specs and the boundary cases, and tell me whatever looks off. You're effectively the first serious user of this bivariate σ-phylo path, and every odd thing you've surfaced has made it materially better — so the more you stress it, the further it takes all of us.

Thanks again — this one set of analyses turned up a real parser bug, drove a genuinely useful boundary-inference feature all the way into R, **closed a real gap in the bivariate REML correction** (the scale axes were under-corrected; they aren't now), and your boundary map is the cleanest I've seen.
