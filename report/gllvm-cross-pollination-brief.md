# Cross-pollination brief — what DRM.jl / drmTMB can offer the GLLVM.jl team

*Draft 2026-06-11; refreshed 2026-06-12 after the σ-phylo location–scale
subsystem landed (`src/gaussian_locscale_phylo.jl`, `src/locscale_*.jl`). Held
for go-ahead before filing any issue on the GLLVM repo. This is the OFFER
direction (what we give); the reverse (what we learned from gllvm/gllvmTMB) lives
in `report/GLLVM-porting-playbook.md` and
`report/gllvmtmb-lessons-for-julia-bridge.md`.*

**Scope of this brief: methods, not code.** Everything below is an idea / recipe
/ pointer to our own MIT-licensed verification harness. We share *what* and
*why*, never a copy of source from either package. The license boundary is hard:
DRM.jl is MIT, drmTMB is GPL(≥3); GLLVM/gllvmTMB carry their own licenses. None of
that source crosses in either direction — only transferable methods and our own
generated outputs.

## Why share

DRM.jl (distributional phylogenetic regression) and GLLVM.jl (generalized linear
latent-variable / ordination models) are sister Julia packages with a **clean,
non-overlapping niche split** and a shared sparse-Laplace + AD substrate. We
solved several problems on our side of the line that transfer directly; we have no
interest in crossing into their arbitrary-K ordination turf (that is the boundary,
not a gap). Sharing is mutual and respects both niches.

## The boundary (so the offer is unambiguous)

- **DRM.jl / drmTMB:** ≤ 2 responses / latent factor — distributional regression
  (a formula per parameter: μ, σ, ρ12), with phylogenetic / structured covariance.
- **GLLVM.jl:** arbitrary-K latent factors — ordination, JSDM, model-based
  multivariate. We do **not** want this; > 2 / latent-factor is their field.

We meet at the **sparse-Laplace marginal + exact-gradient** machinery. That is
where the transferable pieces live.

## The shared failure mode (the pitch in one paragraph)

A GLLVM over-factors and **a latent factor's variance collapses to 0**; loadings
go collinear and a loading correlation pins to **ρ → ±1**. At exactly that point
the Wald Hessian is singular and the optimiser reports "Hessian not
positive-definite" — a *crash* where the honest answer is a *result*: "this factor
carries no signal." DRM.jl hits the **identical** boundary on its own variance /
correlation parameters — a σ-phylo SD collapsing to 0 under weak dispersion
signal, a mean↔σ group correlation pinning to ±1 — and we just shipped the
toolkit that turns that crash into a reported interval. The K-selection /
over-factoring problem is a boundary-inference problem, and the boundary
machinery below is exactly the part that transfers.

## What we offer (4 transferable pieces, in priority order)

### 1. Boundary-corrected inference (the variance-on-the-boundary problem) ★

This is the headline. We built three complementary tools, now landed and wired,
each useful at the boundary where the Wald Hessian is singular:

- **Profile-likelihood CIs that report `[0, x]` honestly.** Two implementations,
  same idea:
  - `src/locscale_profile.jl` — a **Venzon–Moolgavkar guarded-Newton** root-find
    on the profile deviance, using the **envelope-theorem slope** (the idx-component
    of the exact gradient at the constrained optimum, `_ls_profile_ci` →
    `_ls_profile_root`, `locscale_profile.jl:89,141`) with a bracket/bisection
    safeguard for guaranteed correctness — far fewer constrained re-optimisations
    than fixed bisection. When the profile never crosses the χ²₁ threshold, or the
    constrained solve becomes infeasible because Λ is driven near-singular
    (`_LS_PROFILE_INFEASIBLE`, `locscale_profile.jl:31`), the endpoint is returned
    as the **boundary** (±Inf / the edge), not a crash (`locscale_profile.jl:96–103`).
  - `src/gaussian_locscale_phylo.jl` — `_glsp_profile_ci`
    (`gaussian_locscale_phylo.jl:93`) is the boundary-aware variant specialised to
    a log-SD parameter: it brackets the χ²₁ threshold, and **when the profile never
    crosses going DOWN (logL → −∞, SD → 0) it returns lower endpoint = 0** — an
    honest `[0, x]` CI on the SD scale (`gaussian_locscale_phylo.jl:119,128–129`)
    instead of a singular-Wald failure. The excursion is capped at ±8 in log-SD
    (an SD ratio ≈ 3000×); beyond that the component is "effectively unidentified,
    so report the boundary rather than chasing the threshold into the region where
    the inner solve is ill-conditioned" (`gaussian_locscale_phylo.jl:112–116`).
    This is wired through `drm(...; profile_ci = true)` and emitted as
    `:profile_ci_sd_sigma` / `:profile_ci_sd_mu` (`gaussian_locscale_phylo.jl:300,
    377–378`).

- **χ̄² (chi-bar-squared) mixture LRTs for "is this variance / factor 0?"**
  `src/chibar.jl`: `chibar_pvalue` / `lrt_boundary` (`chibar.jl:83,134`) implement
  the Self & Liang (1987) / Stram & Lee (1994) boundary correction. For q = 1 the
  null is `0.5·χ²₀ + 0.5·χ²₁` → `p = 0.5·P(χ²₁ > stat)`; for two **independent**
  boundary parameters it is `0.25·χ²₀ + 0.5·χ²₁ + 0.25·χ²₂` (`chibar.jl:48–60,
  85–94`). The naïve χ²(q) reference **over-states the p-value** (conservative,
  ≈ 2× too large for q = 1) — `lrt_boundary` returns BOTH so the correction is
  visible (`chibar.jl:113–116, 138–139`). **Directly the K-selection test:**
  "dropping this factor's variance" is exactly a variance-component-at-zero LRT.
  *Honest caveat we carry and you should too:* the clean 0.25/0.5/0.25 weights
  assume the two boundary components are **independent** (uncorrelated information);
  with correlated loadings the mixture weights follow the cone geometry of the
  information matrix (Stram–Lee) and the simple weights are only approximate
  (`chibar.jl:21–24, 64–66`). Our q ∈ {1,2} closed forms are the base case; the
  general K-factor cone weighting is the natural extension on your side.

- **Penalised / weakly-informative stabilisation to lift a near-0 variance off
  the floor.** When you want a *point* estimate rather than an interval, a small
  penalty (Chung, Rabe-Hesketh, Dorie, Gelman & Liu 2013 — the blme-style penalty)
  moves the estimate off the exact boundary and restores a pd Hessian. We use the
  same logic structurally in the engine: the **unused latent axis is pinned to a
  fixed tiny variance** `ε = 1e-6` (`_SIGMA_RE_EPS`, `locscale_sigma.jl:28`;
  `_glsp_asym_Λ`, `gaussian_locscale_phylo.jl:139–142`) precisely because
  "optimising over logL22 is ill-conditioned (unbounded below)" when an axis
  carries no signal (`locscale_sigma.jl:16–22`). Same disease, same cure: a floor
  keeps Λ PD while the data decide the identified components. For GLLVM this is the
  recipe to keep an over-specified factor's variance numerically well-behaved
  without forcing it to a hard 0.

- **The honest framing (the part that matters most).** None of these makes an
  unidentified component identifiable. **When the signal is absent, the boundary
  CI `[0, x]` IS the result** — that is the answer, reported as data, not a
  numerical failure. Reparameterisations (log-Cholesky for Λ, Fisher-z for ρ) keep
  the optimiser well-behaved but *relocate* the boundary to ±∞ in the
  transformed coordinate — they do not dissolve it. The discipline is: detect the
  boundary, report it as `[0, x]` / `[−1, +1]`, and say "this factor ≈ 0" out loud.

*Transfers to:* CIs/tests on GLLVM loading/variance parameters, and the
K-selection / over-factoring problem in particular. We share the recipe + our
χ̄²/profile verification harness — methods, not code.

### 2. The O(p) Takahashi sparse-phylo EXACT gradient recipe

`src/takahashi_selinv.jl` (`takahashi_selinv`, `takahashi_diag`,
`takahashi_selinv.jl:103,199`). The load-bearing trick: the Laplace marginal
gradient needs entries of `Q⁻¹` for a sparse precision `Q`, which cost O(p²)/O(p³)
densely. The Takahashi (1973) / Erisman–Tinney (1975) recursion returns exactly the
entries at the `L + Lᵀ` Cholesky-fill pattern in **O(nnz(L))**; on a
tree-structured precision the elimination tree has constant below-diagonal degree,
so `nnz(L) = O(p)` and the selected inverse is genuinely linear
(`takahashi_selinv.jl:8–13`). The family enters ONLY through the per-observation
leaf derivatives — one recipe serves every family. **Read the caveat we
documented before adopting** (`takahashi_selinv.jl:14–35`): the selected inverse
is exact *only* at in-pattern entries; dense leaf-to-leaf covariance blocks are NOT
in pattern and stay O(p²) — the swap is linear for diagonal / Q-pattern accumulators
(the variance-component gradient, the EM E-step's `diag(V_φ)`), not for everything.
Verified ≤ 1e-6 vs finite differences and O(p) to p = 10,000 on our side.

*Transfers to:* any GLLVM model with a structured (phylogenetic/spatial) latent
covariance, replacing dense or autodiff-through-Cholesky gradients — with the
honest scope limit above.

### 3. The location–scale (distributional) model on a structured latent

We model the **dispersion** (not just the mean) as its own structured sub-model,
through a Laplace core that is **symmetric in the mean (η) and scale (ψ) axes**
(per-obs loadings `Zη` / `Zψ`). The newly landed σ-phylo subsystem is the worked
proof:

- `src/gaussian_locscale_phylo.jl` — Gaussian μ-and-σ both carrying a phylogenetic
  RE, in three blocks that share ONE `_fit_locscale` engine
  (`gaussian_locscale_phylo.jl:232`): **SEPARATE** (Λ = diag(L11², L22²), mean-phylo
  ⊥ σ-phylo — the capability we note drmTMB lacks, `:12–16`), **COUPLED** (free L21
  → a mean↔σ group correlation, `:42–44, 382`), and **ASYMMETRIC** (σ-phylo only,
  mean fixed, `:138–181, 244`).
- `src/locscale_sigma.jl` — standalone `sigma ~ 1 + (1|g)` for non-Gaussian
  families: put the latent **entirely on the scale axis** (`Zη = 0`, `Zψ = [1 0]`,
  `locscale_sigma.jl:33–38`), the q=2 spine handles it unchanged.
- `src/locscale_corr.jl` — the same spine reroutes the correlated /independent
  random slope (`(1+x|g)`, `(0+x|g)`), and a **structured Q** (phylo / spatial)
  routes the `kron(Q, Λ⁻¹)` prior through the identical core
  (`locscale_corr.jl:92–95`).

The key idea for GLLVM: because the core is axis-symmetric, the latent can load the
scale predictor as easily as the mean — so a heteroscedastic / dispersion-structured
latent-variable model needs no new kernel, only a different loading matrix.

*Transfers to:* heteroscedastic / dispersion-structured GLLVM variants — model the
*scale* of a latent response, not only its location.

### 4. The R ↔ Julia bridge pattern (engine = "julia")

A general formula-string → `bf()` bundle → `drm()` translation layer
(`src/bridge.jl`: `drm_bridge`, `_bridge_formula`, `bridge.jl:25,183`) plus an
R-side `drmTMB(..., engine = "julia")` route (`drmTMB/R/julia-bridge.R`:
`drmTMB_julia_bridge`, `R/julia-bridge.R:21`) with **family gating** so only
parity-tested cells route (`drm_julia_locscale_phylo_families`,
`drm_julia_slope_phylo_families`, `R/julia-bridge.R:160,167`) and a
**finite-and-sane** floor on the returned vcov where the bridge is the only route
(`finite_vcov <- all(is.finite(V))`, `R/julia-bridge.R:884`), with a ≤ 1e-6 parity
gate where both engines fit. *Transfers to:* giving an R GLLVM front-end a fast
Julia engine without rewriting the R API — including how to *gate* which cells are
safe to route and how to floor the output contract where there is no R fallback to
compare against.

## What we'd borrow back (post-CRAN, explicitly NOT now)

- **Family breadth:** their ordinal / multinomial / Tweedie leaf catalogue.
- **Latent Matérn / NNGP kernels:** for our spatial side (our #270).
- **The general K-factor χ̄² cone weighting:** our chibar.jl stops at independent
  q ∈ {1,2}; the correlated-component cone geometry is exactly the over-factoring
  case and is more naturally their problem to generalise.

## Concrete deliverables (to file on go-ahead)

1. A markdown note (this brief, trimmed) on the GLLVM repo's discussions.
2. Draft issues we'd open as cross-references:
   - DRM.jl **#269** (Pagel-λ) and **#270** (Matérn / NNGP kernels) — tagged as the
     borrow-back wishlist, so their kernel work and ours converge.
   - A GLLVM issue: "Takahashi O(p) exact gradient for structured latent
     covariance — recipe + our verification harness (and the in-pattern caveat)."
   - A GLLVM issue: "Boundary-valid CIs/LRTs (profile + χ̄²) for variance/loading
     parameters — report 'this factor ≈ 0' as a result, not a crash."
3. A pointer to the verification harness (FD ≤ 1e-6 gate, O(p) scaling bench) so
   they can reproduce before adopting.

## Tone for the outreach

Mutual and niche-respecting: "we solved the structured-covariance gradient + the
boundary inference on our ≤2 side; here's the recipe and the proof; your
arbitrary-K ordination is yours; can we converge on shared kernels — and on the
general-K χ̄² cone weights — post-release?" Not "we're faster" — "here's a
transferable method, verified, take what's useful; the boundary is often the
answer."
