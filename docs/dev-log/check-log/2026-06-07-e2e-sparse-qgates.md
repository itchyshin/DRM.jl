# Check-log: end-to-end sparse phylo (#232) + engine Q-gates #15/#16

> **Status: UNVERIFIED in-session.** No Julia runtime (package servers blocked).
> Verification is **CI-only** via the PR's GitHub Actions (`test (1)`,
> `test (1.10)`, `docs`). Nothing is "verified" until those are green.

## What was checked (by construction / derivation, pending CI)

### A — end-to-end sparse phylo (#232)
- **Augmented-precision identity.** `augmented_tree_precision` returns the
  root-conditioned `Q = Q_topology[keep,keep]`, identical to what
  `sigma_phy_dense` inverts. So `(Q⁻¹)[leaf,leaf] == sigma_phy_dense` exactly —
  the added test pins this on both balanced and caterpillar trees.
- **Correlation match.** The dense `phylo(1|g)` path uses the leaf CORRELATION
  `C = D^{-1/2} Σ D^{-1/2}`. The end-to-end path keeps the augmented latent in the
  COVARIANCE precision `Q` and folds `D^{-1/2}` into the incidence weights
  (`a_c = D^{-1/2} ã`), which is the exact reparametrisation `Z_corr a_c =
  (Z_corr D^{-1/2}) ã`. So logLik/β/σ/re_sd match the dense fit; only the latent
  basis differs. Leaf variances `D` come from ONE Takahashi selinv of `Q` (O(p)).
- **Homoscedastic reduction.** The general `sigma ~ x` gradient was reduced
  algebraically to #231's `glσ = (n − tr(H⁻¹ZᵀZ)/σ²) − σ²‖u‖²` at `Xσ = 1`
  (verified term-by-term), confirming the spec engine is a strict generalisation.
- **logdet bookkeeping.** `logdet V = logdet D − logdet P + logdet H`,
  `logdet D = −Σ log w` (heteroscedastic), `logdet P = −2Σ mₖ lσₖ − Σ logdet(Qₖ⁻¹)`.

### B — Q-gates
- **#15 zero-alloc.** `aug_prior_grad!` is `mul!(g, P, u)` into a preallocated
  buffer — zero-alloc by construction and p-independent (a sparse matvec allocates
  nothing). The CHOLMOD factor/solve is EXCLUDED (out-of-Julia-control), per the
  design's pure-Julia-arithmetic option. TEETH demonstrated in-test: the
  allocating `P*u` reference is `> 0` and grows with p.
- **#16 multi-shape.** `bench/run_scaling.jl` already sweeps balanced +
  caterpillar with an exponent gate (`k ≤ 1.6` when ≥3 p-values); the new library
  `random_caterpillar_tree` + the `workflow_dispatch` CI job complete the wiring.

## Tests / gates added
- `test/test_two_structured_gaussian_sparse.jl`: augmented-precision == dense leaf
  cov; caterpillar well-formed; END-TO-END phylo == dense fit (#232 anchor);
  `sigma ~ x` dense-GLS gradient ≈ 0 at the sparse MLE.
- `test/test_qgate_alloc_inner.jl` (wired into `runtests.jl`): #15 zero-alloc gate
  + teeth.
- `.github/workflows/CI.yml`: `scaling-sweep` (`workflow_dispatch`) for #16.

## Known-unknowns for CI
- `cholesky!(F, H; check=false)` pattern-reuse: best-effort with a fresh-cholesky
  fallback in a try/catch, so a CHOLMOD pattern-mismatch can't break correctness
  (only forgo the symbolic-reuse speedup).
- The #231 anchor tests call `_fit_two_structured_gaussian_sparse` (now a wrapper
  over the spec engine) — `_remap_resid_block` restores the historical block names
  so `re_sd`/`sigma`/`ranef`/`coef` are byte-compatible.
- `@allocated == 0` can be sensitive to Julia version inlining; both 1.10 and 1
  are exercised by the matrix.
