# Design: coevolution front end (q=4 PLSM public API) — #187

**Status:** design / implementation map — **API decision locked** (per-predictor
`phylo(1 | g)` markers, option A below). No engine changes. Implementation +
verification happen in a local Julia session (the cloud env has no runtime).
Part of the coevolution epic **#186**; unblocks accessors **#188** and the
spatial/relmat variant **#189**.

## Goal

Let a user fit the **bivariate phylogenetic q=4 PLSM** — the project's headline
model (`report/why-q4-plsm-matters.md`; #8) — from the public `bf()` / `drm()`
front end, reaching the **already-verified engine** instead of the residual-only
bivariate path. One worked call should fit the shared 4×4 `Σ_a` and return a
`DrmFit` from which #188 can read the coevolution correlations.

## What already exists (do not modify)

The hard part is done and benchmarked. Verified pieces, with entry points:

| Piece | Symbol / file | Role |
|---|---|---|
| Engine | `fit_q4_sparse_tmb(prob::AugProblem, Q_cond; β0, Λ0, …)` — `src/fit_q4_sparse_tmb.jl:292` | Sparse augmented-state Laplace ML fit; exact O(p) gradient (`marginal_and_exact_grad`). Returns `(; θ, β, Λ, loglik, converged, iterations, …)`. |
| Problem builder | `make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr; species)` — `src/sparse_em_fit.jl:18` | Builds `(prob::AugProblem, Q_cond::SparseMatrixCSC)` from a phylogeny + the five design matrices. `species[i]` maps data row `i` → tree tip. |
| θ layout | `unpack_theta` / `pack_theta` / `lc_to_Λ` / `Λ_to_lc` — `src/fit_q4_sparse_tmb.jl:48`, `src/fit_ml_q4.jl:11` | `θ = [β(7); lc(10)]`; `β = (mu1,mu2,s1,s2,rho)`; `lc` = log-Cholesky of the 4×4 `Λ` (= `Σ_a`). |
| Tree → precision | `AugmentedPhy`, `random_balanced_tree`, `sigma_phy_dense` — `src/sparse_phy.jl` | `make_problem` consumes `phy.{n_total, root_index, Q_topology, leaf_indices, n_leaves}`. Only a **synthetic** tree builder exists today. |
| Front end (residual) | `bf(; mu1, mu2, sigma1, sigma2, rho12)` + `drm(::BivariateDrmFormula, ::Gaussian; data)` — `src/gaussian_bivariate.jl:70,85` | Fits the **residual**-correlation `rho12` model; never reaches the engine; takes no tree. |

A complete, working end-to-end template already lives in the `fit_ml_q4.jl`
driver block (`src/fit_ml_q4.jl:69`):

```julia
prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
r = fit_q4_sparse_tmb(prob, Q_cond; β0 = (mu1=X1\y1, mu2=X2\y2, s1=[…], s2=[…], rho=[0.0]))
r.β            # (mu1, mu2, s1, s2, rho)
r.Λ            # the fitted 4×4 Σ_a   ← the coevolution block
r.loglik
```

**The front end is exactly the glue from `(BivariateDrmFormula, data, tree)` to
that call, plus packaging the result as a `DrmFit`.**

## The gap (precise)

1. `bf()` / `BivariateDrmFormula` (`src/gaussian_bivariate.jl:16`) has **no slot**
   for a group-level structured marker.
2. `drm(::BivariateDrmFormula, ::Gaussian)` has **one** branch (residual `rho12`);
   it never builds `prob`/`Q_cond` and takes no `tree`/`coords`.
3. `DrmFit` (`src/gaussian_core.jl:120`) has **no field** for the fitted 4×4 `Σ_a`.
4. `make_problem` needs an `AugmentedPhy`; there is **no constructor from a user
   tree** (Newick / R `phylo`) — only the synthetic `random_balanced_tree`. This
   is **#19** and is a hard dependency for *real-tree* fits (but **not** for
   testing — see "Dependencies").

## Public API — **decided: per-predictor markers (option A)**

The engine is **hardwired to q=4** (all four effects `a_l1, a_l2, a_s1, a_s2`
share one `Σ_a`). The API must map onto that. The chosen spelling is **(A)**
below (per-predictor `phylo(1 | g)` markers, q=4-required); **(B)** is recorded
as the considered alternative.

- **(A) Per-predictor markers, all four required** ✅ **chosen** — drmTMB-faithful:
  ```julia
  drm(bf(mu1    = y1 ~ x + phylo(1 | species),
         mu2    = y2 ~ x + phylo(1 | species),
         sigma1 = sigma1 ~ 1 + phylo(1 | species),
         sigma2 = sigma2 ~ 1 + phylo(1 | species)),
      Gaussian(); tree = tree)
  ```
  Reads naturally, matches the univariate `phylo(1 | g)` marker, and is
  forward-compatible: relaxing "all four required" later (when a variable-q
  engine exists) is purely additive. For the first slice, **validate that the
  same `phylo(1 | g)` marker is present on all four** and error otherwise
  ("the verified q=4 engine requires a shared phylogenetic effect on
  μ1, μ2, σ1, σ2").

- **(B) Single shared marker** *(considered, not chosen)* —
  `drm(bf(...), Gaussian(); tree, phylo_group=:species)`, no markers in the
  formulas. Simpler to parse but diverges from drmTMB spelling and the
  univariate `phylo()` convention.

**Rationale for A:** it matches drmTMB and the existing univariate `phylo(1 | g)`
marker (one grammar to learn), and it is forward-compatible — when a variable-q
engine later allows the σ effects to be dropped (q=2), relaxing the "all four
required" validation is purely additive, with no API change. The "all four
required" check is the only A-specific guard; everything downstream of parsing is
identical under A or B.

## Internal data flow (implementation)

In `drm(f::BivariateDrmFormula, fam::Gaussian; data, tree=nothing, …)`:

1. **Detect** a group-level marker via the existing `_split_ranef` on each form
   (`src/gaussian_structured.jl`). If none → **unchanged** residual path (no
   behaviour change). If present → structured branch below.
2. **Build the five design matrices** from the *fixed* part of each form (strip
   the marker), exactly as the residual path already does with `_design`
   (`gaussian_bivariate.jl:87–91`): `X1, X2, Xs1, Xs2, Xr`. (`rho12` stays the
   residual ρ design; the engine's `rho` block is the residual correlation —
   the phylogenetic correlations live in `Σ_a`, not here.)
3. **Resolve the phylogeny** → an `AugmentedPhy` and the row→tip map `species`:
   - real tree: from `tree` via the #19 constructor (when available);
   - interim/testing: accept a precomputed `AugmentedPhy` or a known precision
     (lets #187 be tested against synthetic trees / known matrices *before* #19).
4. `prob, Q_cond = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr; species)`.
5. `r = fit_q4_sparse_tmb(prob, Q_cond; β0 = (mu1=X1\y1, mu2=X2\y2,
   s1=[log std…], s2=[log std…], rho=[0.0]))`.
6. **Package a `DrmFit`** (next section).

## `DrmFit` packaging

- `blocks`: `[:mu1=>1:k1, :mu2=>…, :sigma1=>…, :sigma2=>…, :rho12=>…, :phylocov=>lc-range]`.
  The `:phylocov` (10 log-Cholesky params) block has **no entry in `forms`**, so
  the existing `predict` / `predict_parameters` skip logic
  (`haskey(forms, p)`, `gaussian_core.jl:631`) ignores it automatically — same
  pattern as the univariate `:resd` / `:recov` blocks.
- `means` / `obs` / `scales`: as in the residual path
  (`gaussian_bivariate.jl:126–130`) — `scales[:rho12]` remains the **residual**
  correlation; `Σ_a` is **not** a per-obs scale.
- **`Σ_a` storage:** stash a NamedTuple in the free-form `ranef::Any` field via
  `_withranef`, e.g. `(; Sigma_a = r.Λ, blups = û, Q_cond, phy)`. #188's
  `coevolution(fit)` reads `fit.ranef.Sigma_a`. *(Alternative: add a dedicated
  `structcov` field to `DrmFit` — a wider but more explicit change. Flag for the
  maintainer; `ranef` keeps the struct stable.)*
- **`vcov`:** `fit_q4_sparse_tmb` returns no Hessian. For first-slice **β-block
  SEs**, compute a finite-difference Hessian of the 17-dim marginal `θ ↦ nll` at
  `θ̂` (cheap; ForwardDiff can't cross the CHOLMOD factor, so use FD or the
  numeric-Hessian path in `inference.jl`). **`Σ_a` CIs are out of scope here** —
  they are #188 via the profile / bootstrap derived-scalar machinery.
- Attach the marginal `nll` closure via `_withnll` so profile intervals work.

## Dependencies & sequencing

- **#19 (tree marshalling)** — needed for *real* Newick/`phylo` input. **Not** a
  blocker for landing/testing #187: build the structured branch against a
  precomputed `AugmentedPhy` (synthetic `random_balanced_tree`) and/or a
  user-supplied precision first; wire Newick parsing when #19 lands.
- **#188 (accessors)** — consumes `fit.ranef.Sigma_a`; can proceed in parallel
  once the storage shape here is fixed.
- **#189 (spatial/relmat)** — swaps the precision source feeding `make_problem`;
  builds directly on this branch.

## Test plan (local Julia — the verify-before-claiming bar)

1. **Recovery:** simulate from a known `Σ_a` (reuse the `fit_ml_q4.jl:72–81`
   simulator) on a balanced tree; assert all four ρ_a and the four σ_a recover
   within tolerance.
2. **Gradient:** analytic vs finite-difference on the marginal ≤ 1e-6 (the engine
   already meets this — assert the front end doesn't break it).
3. **No-regression:** a no-marker `bf()` fit is bit-for-bit the current residual
   path; the verified q=4 baseline logLik is unchanged when called directly.
4. **Skip-logic:** `predict` / `predict_parameters` ignore `:phylocov`.
5. **Round-trip (later):** vs drmTMB generated outputs once #19 + R-parity land.

## Implementation checklist

- [ ] Extend `bf()` / `BivariateDrmFormula` to carry a structured marker (parse via `_split_ranef`).
- [ ] Add the structured branch to `drm(::BivariateDrmFormula, ::Gaussian)` (steps 1–6 above); keep the residual default untouched.
- [ ] Interim `AugmentedPhy`/precision entry point (pre-#19), with the `species` row→tip map.
- [ ] `DrmFit` packaging: `:phylocov` block + `Σ_a` in `ranef` + FD β-vcov + `_withnll`/`_withranef`.
- [ ] Tests 1–4; a worked example in `tutorials/bivariate-coscale.md` (or a new coevolution article — coordinate with #188's readout).
- [ ] Update `report/` if the grammar/RE behaviour changes (per `CLAUDE.md`).
