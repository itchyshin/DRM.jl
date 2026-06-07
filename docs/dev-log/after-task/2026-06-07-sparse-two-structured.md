# After-task: sparse O(p) path for the two-structured Gaussian model (#225 follow-up)

> **Status: UNVERIFIED in-session.** No Julia runtime; CI-only verification via
> the PR's GitHub Actions. Do not promote any claim to "verified" until green.

## Scope

Follow-up to #225 (dense `_fit_two_structured_gaussian`): an **opt-in sparse
path** for the SAME model

    y = Xβ + Z₁a₁ + Z₂a₂ + ε,  a₁~N(0,σ₁²C₁), a₂~N(0,σ₂²C₂), ε~N(0,σ²I),
    y ~ N(Xβ, V),  V = σ²I + σ₁² Z₁C₁Z₁ᵀ + σ₂² Z₂C₂Z₂ᵀ.

The dense path assembles + Cholesky-factors the n×n `V` each evaluation (O(n³)).
The sparse path never forms `V`: it integrates the augmented latent `a = [a₁;a₂]`
via ONE sparse Cholesky of the m×m `H = blockdiag(σ₁⁻²C₁⁻¹, σ₂⁻²C₂⁻¹) + ZᵀZ/σ²`
(m = G₁ + G₂), and computes the marginal logLik + variance-component gradient
from the sparse factor's logdet and the **Takahashi selected inverse** — the same
logdet/derivative recipe as the verified q4 PLSM engine. Because the data term is
Gaussian, the inner "mode" is a single linear solve `â = H⁻¹b` (no Newton).

## Changes

- `src/gaussian_structured.jl`
  - `_fit_two_structured_gaussian_sparse` — the sparse fitter (same signature as
    the dense fitter). Closed-form marginal NLL + **analytic** gradient over
    `[βμ; logσ; logσ₁; logσ₂]`; FD Hessian (of the analytic grad) for SEs; BLUPs
    `â = H⁻¹b` via `ranef`; same `blocks`/`names`/`scales` as the dense fit so
    `re_sd`/`vc`/`sigma`/`ranef`/`coef` work unchanged.
  - Helpers `_sparse_incidence`, `_trace_block_selinv`, `_trace_selinv_full`
    (read selected-inverse entries at the ZᵀZ / Qₖ pattern).
  - Imports from `SparseArrays`.
- `src/gaussian_core.jl` — `drm(::DrmFormula, ::Gaussian)` accepts
  `algorithm = :sparse` and routes the two-structured case to the sparse fitter.
  **Default (`:auto`) is unchanged** (dense path).
- `test/test_two_structured_gaussian_sparse.jl` (wired into `runtests.jl`) —
  equivalence anchor (logLik `rtol 1e-5`), gradient-at-optimum check, larger
  recovery fixture (p=120, tree + banded), and the `algorithm = :sparse` routing.

## Equivalence achieved (target, pending CI)

- logLik dense vs sparse: `rtol 1e-5` on the anchor fixture.
- β, σ, σ₁, σ₂: `rtol 1e-4`.

## Honesty / caveats

- **Wall-clock speedup is UNMEASURED here** (no runtime). The O(p) claim is
  asymptotic/structural: the cost per eval is the sparse Cholesky of `H` plus a
  Takahashi pass, both O(nnz(L)); for tree / sparse-Ainv precisions nnz(L) = O(p),
  vs the dense path's O(n³). No benchmark was run — treat as *expected*, not
  measured.
- **Equivalence is anchored on sparse-inverse correlations.** For phylo the
  router still resolves the DENSE leaf correlation (`_phylo_correlation`), so the
  sparse path inverts a dense Cₖ to get Qₖ — correctness is preserved (same MLE)
  but that inversion is O(G³) one-off; a fully sparse phylo precision would feed
  the augmented tree precision directly (future work; needs the augmented-state
  router to bypass `_corr`). The equivalence/recovery tests still exercise a
  genuinely sparse `H` (banded Qₖ + tree).
- **Residual is `sigma ~ 1`** (homoscedastic), matching the dense path.
- Default behaviour unchanged; sparse is strictly opt-in via `algorithm = :sparse`.

## Follow-ups (propose tracking issue)

- Feed the augmented tree precision (`AugmentedPhy.Q_topology`, root-conditioned)
  and Henderson's sparse `Ainv` directly into `H`, bypassing the dense Cₖ inverse,
  for a truly end-to-end O(p) phylo+animal fit.
- Reuse a single symbolic Cholesky analysis across evals (Julia's `cholesky`
  convenience API re-analyses each call).
- `sigma ~ x` (D → diag) extension.
