# Check-log: sparse O(p) path for the two-structured Gaussian model

> **Status: UNVERIFIED in-session.** No Julia runtime in this cloud session
> (package servers blocked). Verification is **CI-only** via the PR's GitHub
> Actions (`test (1)`, `test (1.10)`, `docs`). Nothing here is "verified" until
> those checks are green.

## What was checked (by construction / derivation, pending CI)

- **Marginal NLL identity** (matrix-determinant lemma + Woodbury) re-derived and
  matched term-by-term to the dense `_fit_two_structured_gaussian`:
  - `logdet V = n logσ² − logdet P + logdet H`, `H = P + ZᵀZ/σ²`,
    `P = blockdiag(σ₁⁻²C₁⁻¹, σ₂⁻²C₂⁻¹)`.
  - `rᵀV⁻¹r = rᵀr/σ² − bᵀâ`, `b = Zᵀr/σ²`, `â = H⁻¹b` (one linear solve — the
    Gaussian "inner mode").
- **BLUP identity** `â = Σ Zᵀu` (with `u = V⁻¹r = (r − Zâ)/σ²`) proved
  algebraically using `ZᵀZ/σ² = H − P` and `Hâ = b`; lets the gradient reuse `â`
  directly (no second solve, no dense Cₖ).
- **Analytic variance-component gradient** derived and matched to the dense
  `½tr(V⁻¹Vₖ) − ½uᵀVₖu` form; logdet-derivative traces `tr(H⁻¹ZᵀZ)` and
  `tr(σₖ⁻²Qₖ H⁻¹)` read off the **Takahashi selected inverse** of `H` at the
  (sparse) ZᵀZ / Qₖ pattern — both ⊆ the `L+Lᵀ` pattern (Cholesky fill closure),
  so every selinv lookup is in-pattern.

## Tests added (`test/test_two_structured_gaussian_sparse.jl`)

1. **EQUIVALENCE anchor** — dense vs sparse on byte-identical inputs (banded-
   precision correlations whose inverse is genuinely sparse): logLik `rtol 1e-5`;
   β, σ, σ₁, σ₂ `rtol 1e-4`.
2. **Gradient sanity** — at the sparse MLE, an independent dense closed-form NLL
   has gradient `< 1e-3` (the optimiser drove it there with the analytic grad).
3. **Recovery, larger fixture** — phylo tree (p=120) + banded animal; σ₁, σ₂, σ,
   slope recovered within tolerance; exercises sparse Cholesky + Takahashi.
4. **Routing** — `algorithm = :sparse` matches the default dense fit (`rtol 1e-4`)
   on the public `drm(...)` path; default stays dense (unchanged).

## Known-unknowns for CI

- CHOLMOD `cholesky(Symmetric(H); check=false)` returns a `CHOLMOD.Factor{Float64}`
  → `takahashi_selinv` consumes it (same idiom as `sparse_laplace_glmm.jl`).
- `Optim.NLSolversBase.only_fg!` with analytic grad (matches the verified core).
- FD Hessian for SEs (cheap; not on the hot path).
