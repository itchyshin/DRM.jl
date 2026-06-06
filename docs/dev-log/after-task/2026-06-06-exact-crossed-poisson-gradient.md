# After-task: exact gradient for K-component crossed Poisson Laplace (#165)

> **Status: UNVERIFIED in-session.** This change was written in a cloud session
> with **no Julia runtime** (the `*.julialang.org` hosts are blocked by the
> environment network policy, so neither `juliaup` nor `Pkg.instantiate()` can
> run). The evidence section below lists the commands to run on a machine with
> Julia; the verification has **not** been performed yet. Do not promote any
> claim here to "verified" until `Pkg.test()` + the new gradient gate pass
> locally.

## Scope

Replaced the last frozen-mode + finite-difference gradient path in the
non-Gaussian Laplace spine with the exact implicit-function gradient.

- File: `src/sparse_laplace_glmm.jl`, `_fit_poisson_crossed_laplace` (the generic
  K-component path; fires for **K ≥ 3** crossed Poisson intercepts, or weighted
  components — K = 1 routes to GHQ, K = 2 to the dense two-block path).
- The frozen block already formed the exact dense `H⁻¹` and exact leverages
  `zᵢ'H⁻¹zᵢ`; it omitted the implicit `db̂/dθ` correction. Added:
  - `tlogdet = Z'(μ ⊙ lever)`, `implicit = H⁻¹ tlogdet`;
  - `gβ -= ½ (Z'diag(μ)X)ᵀ implicit`;
  - `gσ_k += Σ_{j∈k} implicit_j · invvar_j · b_j`.
- Changed the post-fit polish from a finite-difference LBFGS step to an
  exact-gradient `OnceDifferentiable` polish, gated on `polish_iterations > 0`.

### Why this is believed correct (pending the runtime gate)

The generalised formula reduces **term-by-term** to the already-verified
two-block Poisson path `_fit_poisson_crossed_intercepts_laplace` (and mirrors the
non-Gaussian two-block `_fit_crossed_mean_laplace`) when K = 2: `lever`,
`tlogdet`, `crossβ`, `implicit`, and the explicit/implicit `gσ` terms all match.
Derivation is in the code comments (implicit-function theorem on
`L(θ) = f(b̂,θ) + ½ logdet H`).

### Not in this slice

- `#202` (non-Gaussian phylogenetic location–scale; the scale-axis structured RE)
  — separate follow-up that builds on this exact-gradient foundation.
- Scaling the dense `H⁻¹` to a Takahashi selected inverse for very large crossed
  designs (the crossed `q` is small in practice; correctness-first here).

## Evidence (TO RUN — not yet executed)

```sh
julia --project=. test/test_poisson_crossed_laplace.jl   # incl. new K=3 #165 gate
julia --project=. -e 'using Pkg; Pkg.test()'
git diff --check
```

Expected: the new `@testset "Poisson K=3 crossed — exact Laplace gradient (#165)"`
checks the analytic gradient against central finite differences **off the
optimum** (rtol/atol 1e-4) — where a frozen-mode gradient would fail — plus loose
parameter recovery; existing crossed/recovery tests unchanged.

## Verification plan

Re-run the commands above in a session whose network policy permits the Julia
hosts. If the gradient gate fails, the most likely culprits are a sign or factor
in the `gσ` implicit term or a transposition in `crossβ`; cross-check against
`_fit_poisson_crossed_intercepts_laplace`.
