# DRM.jl + drmTMB: a sparse, O(p) distributional-regression twin

*A capability overview for scientists deciding whether to use the packages.*

DRM.jl (MIT, Julia) and **drmTMB** (GPL ≥ 3, R) are a matched pair for
**distributional regression**: instead of modelling only the mean of a response,
you write a separate regression formula for *each* parameter of its
distribution — the mean **μ**, the residual scale **σ**, and, for bivariate
responses, the residual correlation **ρ12**. drmTMB is the mature R front end;
DRM.jl is the Julia engine, reachable directly or from R via
`drmTMB(..., engine = "julia")`. The two share a grammar and a parity contract,
so a model written for one reads almost verbatim in the other.

This document states what the pair can do **today**, marks what is **planned**,
and is deliberate about which numbers are *measured* versus *extrapolated*. Every
performance figure below is reproduced from `report/comparison-grid.md` or a named
benchmark file; none are invented, and extrapolated numbers are flagged as such.

---

## 1. Distributional regression: a formula per parameter

The front end is `bf(...)` — one formula per distributional parameter:

```julia
# univariate Gaussian location–scale: model the mean AND the spread
drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)

# bivariate Gaussian: a mean and scale per response, plus residual correlation
drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
       sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
       rho12 = @formula(rho12 ~ 1)), …)
```

Naming is fixed and shared across the twin: **`sigma`** for scale (never `tau`),
**`rho12`** for the bivariate *residual* correlation. Group-level (phylo /
spatial / study) correlations are reported as named covariance summaries, not as
`rho12`. **ML is the default** (REML likelihoods are not comparable across
fixed-effect structures, so ML is what you need for model selection); REML is an
opt-in option where implemented (see §6).

---

## 2. O(p) sparse phylogenetic location–scale — model the variance, not just the mean

The headline capability is a **phylogenetic location–scale model**: a tree on the
*scale* axis, not only the mean. Closely related species can share not just their
average trait value but how *variable* that trait is around its own mean. DRM.jl
fits this through a sparse augmented-state Laplace approximation that never forms
a dense phylogenetic covariance, giving genuinely **O(p)** scaling in the number
of tips.

**Measured, verified (`report/comparison-grid.md` §2–§3):**

- **2.18× faster than drmTMB on a single fit** of the q=4 phylogenetic bivariate
  location–scale model (p = 100): Julia 1.14 s, converged, logLik −256.51, vs
  drmTMB 2.48 s, logLik −256.52, flagged non-converged (nlminb code 8). Both
  engines sit at the same near-singular variance boundary; the 0.01 logLik gap is
  a model-geometry artefact, not an engine bug.
- **Near-perfect O(p) scaling to p = 10,000** on a biological per-dimension-variance
  model (4×4 Λ): wall-clock 0.77 s → 112.9 s from p = 100 to p = 10,000, scaling
  exponent **k = 1.08**, flat iteration counts. The O(p) gradient uses a
  Takahashi selected-inverse and never materialises the dense Σ_phy.

> **Honest scope of the comparison.** The 2.18× is a measured head-to-head at
> p = 100. The O(p) curve is measured for DRM.jl alone. drmTMB was **not** run at
> p > 100 on this model, so any "≈12× at p = 10,000" figure is an *extrapolation*
> of drmTMB's k ≈ 1.36, **not** a measured result — do not cite it as measured.

For non-Gaussian counts, a separate crossed sparse-Laplace benchmark
(`report/crossed-family-benchmark.md`) measured large R/Julia speedups (median
≈ 41× across successful paired Poisson / NB2 cells, n up to 20,000) with
coefficient and random-effect-SD parity; several R cells there are model families
drmTMB does not yet support, so those rows have no head-to-head ratio.

---

## 3. Valid boundary inference where Wald Hessians go singular

Variance components live on a boundary (σ² ≥ 0), and at or near zero the usual
Wald / sdreport machinery breaks: the observed information is not positive
definite and standard errors come back as `NaN`. DRM.jl is built to give
*usable* uncertainty exactly there.

**Measured, verified (`report/comparison-grid.md` §6):**

- At the q4_p100 ML optimum the 17×17 observed information has one negative
  eigenvalue (the singular direction); **16 of 17 parameters still get finite,
  valid Wald SEs** via a floored inverse, in ~0.5 s. **drmTMB's `sdreport` is
  all-NaN on the same fit** — DRM.jl returns usable uncertainty where drmTMB
  returns none.
- A parametric bootstrap through the O(p) precision sampler returned **60/60
  successful, finite CIs** that bracket the estimate. (Timing caveat from the
  source: that run was serial — the threaded ~8× speedup is documented but *not*
  end-to-end verified.)

For the rigorous boundary case, two further tools are wired:

- **Profile-likelihood CIs** for a variance / log-SD parameter
  (`_glsp_profile_ci` in `src/gaussian_locscale_phylo.jl`), boundary-aware: when
  the profile never crosses the χ²₁ threshold going down, the lower endpoint is
  honestly reported at the boundary (`[0, x]`) rather than a spurious Wald
  interval. Opt in with `profile_ci = true`.
- **χ̄² (chi-bar-square) boundary-corrected LR tests** for variance components at
  zero (`src/chibar.jl`), implementing the Self–Liang (1987) / Stram–Lee (1994)
  mixtures for q = 1 (½χ²₀ + ½χ²₁) and q = 2 independent components. Using a naive
  χ²(q) here is conservative; the mixture is the correct reference.

---

## 4. NEW: univariate Gaussian σ-phylo (separate / coupled / asymmetric)

DRM.jl now fits the **univariate Gaussian** phylogenetic location–scale model
directly — a tree on `sigma` in a one-response model. A `phylo(1 | sp)` marker on
the `sigma` formula routes to the location–scale Laplace engine
(`src/gaussian_core.jl` → `_fit_gaussian_locscale_phylo` in
`src/gaussian_locscale_phylo.jl`). Three ways to wire the tree onto the two axes:

| Mode | Tree on… | Λ structure | When |
|---|---|---|---|
| **Separate** (default) | both μ and σ axes | `diag(L11², L22²)`, no cross-term | independent phylo signal on mean and scale |
| **Coupled** | both axes, correlated | full 2×2 Λ with free `L21` | mean and scale phylo effects covary |
| **Asymmetric** | σ axis only (mean is fixed effects) | `diag(ε², L22²)` | tree on the variance alone |

Boundary-aware profile CIs (§3) are available on this route via
`profile_ci = true`. This route closes a prior silent-drop bug where
`sigma ~ phylo(1 | g)` was quietly fitted as `sigma ~ 1`; it now either fits the
real σ-phylo structure or errors clearly. A worked example lives in
`report/sigma-phylo-locscale-article.md`.

**Estimator note:** this route is **ML only**. `method = :REML` is implemented for
the *fixed-effect* univariate Gaussian location–scale cell but is explicitly
rejected for structured / phylo / meta terms (see §6).

---

## 5. Cross-family bivariate

Two responses from **different** families can be modelled jointly through a shared
per-observation latent (`src/mixed_family.jl`): `yₖ ~ famₖ(ηₖ)`,
`ηₖ = Xₖβₖ + λₖ u`, with `u ~ N(0,1)` integrated out by Gauss–Hermite quadrature.
This couples, e.g., a Gaussian trait with a Poisson count. The dependence is
reported on the link/latent scale as
`ρ = λ1 λ2 / sqrt((λ1²+v1)(λ2²+v2))` (Nakagawa & Schielzeth 2010). For
Gaussian × Gaussian the marginal reduces exactly to the residual-correlation
(`rho12`) model; for Gaussian × non-Gaussian all loadings are identified.

---

## 6. The R ↔ Julia twin

drmTMB users reach the Julia engine with one argument: `drmTMB(..., engine = "julia")`
(`R/drmTMB.R`, `R/julia-bridge.R`). The grammar is shared, so a model specified in
R routes to the same DRM.jl engine described above. Two boundaries are worth
knowing before you rely on the bridge:

- **Gaussian σ-phylo is currently walled off on the R side.** The Julia engine
  fits it (§4), but `drm_julia_locscale_phylo_families()`
  (`R/julia-bridge.R:160`) lists only `nbinom2`, `gamma`, `beta` — not
  `gaussian`. To use Gaussian σ-phylo today, call DRM.jl directly; exposing it
  through `engine = "julia"` is **planned**.
- **REML is dropped silently on the Julia route.** `drmTMB(..., engine = "julia")`
  returns into the bridge at `R/drmTMB.R:176` *before* the `REML` flag is read,
  and `drmTMB_julia_bridge()` has no REML parameter, so `REML = TRUE` is ignored
  without warning on this route. On the native `engine = "tmb"` route REML is
  honoured (and is itself restricted to the first univariate Gaussian mixed-model
  slice).

---

## Capability table (at a glance)

| Capability | DRM.jl (Julia, MIT) | via `engine = "julia"` | Status |
|---|---|---|---|
| Distributional regression (μ, σ, ρ12 formulas) | yes | yes | Available |
| Bivariate Gaussian residual correlation (`rho12`) | yes | yes | Available |
| Univariate Gaussian σ-phylo (separate/coupled/asymmetric) | yes | **no** (R bridge omits `gaussian`) | Available in Julia; bridge exposure **planned** |
| Non-Gaussian σ-phylo (gamma, beta, NB2) | yes | yes | Available |
| O(p) sparse phylogenetic engine to p ≈ 10⁴ | yes (k = 1.08, measured) | yes | Verified |
| Cross-family bivariate (shared-latent GHQ) | yes | — | Available |
| Profile-likelihood boundary CIs | yes (`profile_ci = true`) | — | Available |
| χ̄² boundary-corrected LR tests (q = 1, 2) | yes | — | Available |
| Wald SEs where drmTMB `sdreport` is NaN | yes (16/17, measured) | — | Verified |
| REML | fixed-effect Gaussian location–scale only | **dropped silently** on Julia route | Partial (ML is the default everywhere) |

---

## What's coming (planned, not yet available)

- **REML for σ-phylo.** REML currently covers only the fixed-effect Gaussian
  location–scale cell and is rejected for structured / phylo / meta terms; an
  exact REML gradient and production stability for the phylo cells are open work
  (`report/comparison-grid.md` §5, "needs human review"). Until then, σ-phylo is
  ML-only.
- **Non-Gaussian σ-phylo through the R bridge.** The Julia engine fits gamma /
  beta / NB2 σ-phylo today; broadening and tightening the bridge's family list
  (and exposing Gaussian σ-phylo + REML on the Julia route) is the next bridge
  slice.
- **Threaded bootstrap timing** and **χ̄² at a true singular boundary** are
  motivated and partially built but not yet end-to-end verified — treat the ~8×
  threaded figure as a target, not a measured result.

---

### Provenance of the numbers
All measured figures trace to `report/comparison-grid.md` (single-fit 2.18×; O(p)
to p = 10,000, k = 1.08; 16/17 valid Wald SEs; 60/60 bootstrap CIs) and
`report/crossed-family-benchmark.md` (non-Gaussian count speedups). The
drmTMB-at-scale multiple is **extrapolated** and is not presented as measured.
Engine behaviour is cited from `src/gaussian_core.jl`,
`src/gaussian_locscale_phylo.jl`, `src/mixed_family.jl`, and `src/chibar.jl`;
bridge behaviour from `R/drmTMB.R` and `R/julia-bridge.R`.
