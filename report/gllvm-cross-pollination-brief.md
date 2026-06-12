# Cross-pollination brief — what DRM.jl / drmTMB can offer the GLLVM.jl team

*Draft 2026-06-11. Held for go-ahead before filing any issue on the GLLVM repo.
This is the OFFER direction (what we give); the reverse (what we learned from
gllvm/gllvmTMB) lives in `report/GLLVM-porting-playbook.md` and
`report/gllvmtmb-lessons-for-julia-bridge.md`.*

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

## What we offer (4 transferable pieces, in priority order)

### 1. The O(p) Takahashi sparse-phylo EXACT gradient recipe
The load-bearing trick: the Laplace marginal gradient
`∇[ jn + ½logdet H − ½logdet P ]|_{û}` needs only (a) the **diagonal/Q-pattern
blocks of H⁻¹** (Takahashi selected inverse — never the full inverse), (b) a
**Q-pattern Λ-trace** `Mk = −Λ⁻¹ ∂Λ Λ⁻¹`, and (c) **one implicit adjoint**
`w = H⁻¹v`. Cost is O(p) on a tree-structured precision, not O(p²)/O(p³). The
family enters ONLY through the per-observation leaf derivatives — so one recipe
serves every family. Verified ≤ 1e-6 vs finite differences and O(p) to p = 10,000.
*Transfers to:* any GLLVM model with a structured (phylogenetic/spatial) latent
covariance, replacing dense or autodiff-through-Cholesky gradients.

### 2. Boundary-corrected inference (the variance-on-the-boundary problem) ★
Latent-variable variance components and loading correlations routinely sit at/near
their boundaries — a factor variance → 0 when K is over-specified, loadings going
collinear (ρ → ±1) — where the Wald Hessian is singular and Wald CIs are invalid
(the classic "my Hessian isn't positive-definite" failure). We built the honest-
inference toolkit for exactly this, and it transfers directly:
- **Profile-likelihood CIs** (Venzon–Moolgavkar guarded-Newton, bracket-safeguarded):
  report `[0, x]` / `[−1, +1]` honestly where Wald fails.
- **χ̄² (chi-bar-squared) mixture LRTs** (Self & Liang 1987; Stram & Lee 1994): the
  *correct* 50:50 (cone-geometry for multi-parameter) null for "is this variance /
  factor 0?", not the naïve χ²₁ that over-rejects. **Directly useful for K-selection /
  over-factoring** — report "this factor's variance is ≈0" as a *result*, not a crash.
- **Penalised / weakly-informative stabilisation** (Chung, Rabe-Hesketh, Dorie, Gelman
  & Liu 2013, the blme penalty): lift a near-0 latent variance off the exact floor → a
  non-degenerate estimate + a pd Hessian, when you want a point estimate.
- **The honest framing:** none of these makes an unidentified component identifiable —
  when the signal is absent, the boundary CI **is** the result. Reparameterisations
  (log-Cholesky, Fisher-z) keep the optimiser well-behaved but *relocate*, not dissolve,
  the boundary.
*Transfers to:* CIs/tests on GLLVM loading/variance parameters, the K-selection problem
in particular. We share the recipe + our χ̄²/profile verification harness — methods, not
code (MIT/GPL clean).

### 3. The location–scale (distributional) model on a structured latent
Modelling the **dispersion** (not just the mean) as its own structured sub-model,
through a Laplace core that is **symmetric in the mean and scale axes** (per-obs
loadings `Zη`/`Zψ`). *Transfers to:* heteroscedastic / dispersion-structured GLLVM
variants — model the scale of a latent response, not only its location.

### 4. The R ↔ Julia bridge pattern (engine = "julia")
A general formula-string → `bf()` bundle → `drm()` translation layer
(`src/bridge.jl`) + an R-side validator-relaxation + `engine="julia"` route, with
a **finite-and-sane floor** contract where the bridge is the only route and a
≤ 1e-6 parity gate where both engines fit. *Transfers to:* giving an R GLLVM
front-end a fast Julia engine without rewriting the R API.

## What we'd borrow back (post-CRAN, explicitly NOT now)

- **Family breadth:** their ordinal / multinomial / Tweedie leaf catalogue.
- **Latent Matérn / NNGP kernels:** for our spatial side (our #270).

## Concrete deliverables (to file on go-ahead)

1. A markdown note (this brief, trimmed) on the GLLVM repo's discussions.
2. Draft issues we'd open as cross-references:
   - DRM.jl **#269** (Pagel-λ) and **#270** (Matérn / NNGP kernels) — tagged as the
     borrow-back wishlist, so their kernel work and ours converge.
   - A GLLVM issue: "Takahashi O(p) exact gradient for structured latent
     covariance — recipe + our verification harness."
   - A GLLVM issue: "Boundary-valid CIs/LRTs (profile + χ̄²) for variance/loading
     parameters."
3. A pointer to the verification harness (FD ≤ 1e-6 gate, O(p) scaling bench) so
   they can reproduce before adopting.

## Tone for the outreach

Mutual and niche-respecting: "we solved the structured-covariance gradient + the
boundary inference on our ≤2 side; here's the recipe and the proof; your
arbitrary-K ordination is yours; can we converge on shared kernels post-release?"
Not "we're faster" — "here's a transferable piece, verified, take what's useful."
