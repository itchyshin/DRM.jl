# After-task: end-to-end sparse phylo precision (#232) + engine Q-gates #15/#16

> **Status: UNVERIFIED in-session.** No Julia runtime here; CI-only verification
> via the PR's GitHub Actions. No claim is "verified" until the test jobs are green.

## Scope

Two-part build on PR #231's `_fit_two_structured_gaussian_sparse`:

**A) End-to-end sparse (#232).** Feed the ROOT-CONDITIONED augmented tree
precision DIRECTLY as the sparse `Qₖ`, bypassing the dense-`Cₖ` inversion that
#231 left as a caveat — true O(p) for the phylo component. Plus the `sigma ~ x`
(D → diag) heteroscedastic extension.

**B) Engine Q-gates.** #15 — a per-PR zero-allocation gate on the inner Newton
loop's pure-Julia arithmetic. #16 — a `workflow_dispatch` multi-shape scaling
sweep (the bench already does balanced + caterpillar; this adds the library
caterpillar generator + the CI job).

## Changes

### A — end-to-end sparse
- `src/sparse_phy.jl`
  - `random_caterpillar_tree(p; branch_length)` — the maximally-unbalanced ladder
    tree (library version; the bench had a local copy).
  - `augmented_tree_precision(phy) -> (Q, leaf_pos, q)` — the root-conditioned
    augmented topology precision (sparse, O(p) nnz, PD over the `q = 2p-2`
    non-root nodes) + the leaf→row map. This is the sparse precision the
    end-to-end path feeds directly.
- `src/gaussian_structured.jl`
  - `_StructComp` — a per-component spec: sparse `Q`, obs `rows` + `wts`, latent
    dim `m`, `logdetCprior`, `leaf_pos`, `blup_scale`, `grp`.
  - `_dense_comp` — dense leaf-correlation component (`Q = C⁻¹`; #231 behaviour).
  - `_phylo_aug_comp` — END-TO-END phylo component: `Q` = augmented tree precision
    (no dense `Cₖ` inversion). To match the dense path's leaf-CORRELATION
    parameterisation exactly, it folds `D^{-1/2}` (per-leaf-variance rescale) into
    the incidence WEIGHTS (preserving sparsity) and rescales BLUPs back; leaf
    variances come from ONE Takahashi selected inverse of `Q` (O(p)).
  - `_fit_two_structured_gaussian_sparse_spec` — the generalized fitter over two
    `_StructComp`s. Integrates `a = [a₁;a₂]` via a sparse Cholesky of
    `H = blockdiag(σ₁⁻²Q₁, σ₂⁻²Q₂) + ZᵀWZ` reusing ONE symbolic analysis
    (`cholesky!` into a pre-analysed factor; fresh-`cholesky` fallback if the
    pattern check rejects, so correctness never depends on reuse). `W = diag(σ_i⁻²)`
    supports `sigma ~ 1` (homoscedastic) AND `sigma ~ x` (D → diag). logLik via
    det-lemma + Woodbury; variance-component + residual-scale gradients via the
    Takahashi selected inverse (`_diag_ZHinvZt` for the heteroscedastic term).
  - `_sparse_struct_comp` — resolves a marker (phylo/relmat/animal) to a spec.
  - `_fit_two_structured_gaussian_sparse` — the #231 signature kept as a thin
    wrapper (dense-C specs, `sigma ~ 1`) + `_remap_resid_block` so existing
    accessors/tests are unchanged.
- `src/gaussian_core.jl` — `algorithm = :sparse` now routes through the spec
  engine: phylo → augmented precision (end-to-end), relmat/animal → dense `K⁻¹`;
  honours `sigma ~ x`. Default `:auto` unchanged.

### B — Q-gates
- `src/sparse_aug_plsm.jl` — `aug_prior_grad!(g, P, u)` = in-place `mul!(g,P,u)`
  (zero-alloc prior-coupling term); `joint_grad` now uses it.
- `test/test_qgate_alloc_inner.jl` (#15, per-PR) — asserts `@allocated == 0` on
  `aug_prior_grad!` after warm-up at p ∈ {100,1000} (flat), and DEMONSTRATES
  TEETH: the allocating `P*u` reference is `> 0` and grows with p. CHOLMOD factor
  excluded (documented).
- `.github/workflows/CI.yml` — `scaling-sweep` job (`workflow_dispatch` only) runs
  `bench/run_scaling.jl` (balanced + caterpillar, p ∈ {100,1000}; p=10k behind the
  `run_p10k` input), uploads the report. NOT per-PR.
- `src/DRM.jl` — exports `random_caterpillar_tree`, `augmented_tree_precision`,
  `aug_prior_grad!`.

## Tests added (`test/test_two_structured_gaussian_sparse.jl`)
- `augmented_tree_precision` leaf cov == `sigma_phy_dense` (balanced + caterpillar).
- caterpillar topology well-formed + PD precision.
- END-TO-END phylo equals dense leaf-correlation fit (#232 anchor): logLik
  `rtol 1e-4`, β `rtol 1e-3`, re_sd `rtol 2e-3`, σ `rtol 1e-3`; BLUPs length G.
- `sigma ~ x` heteroscedastic: dense-GLS gradient ≈ 0 at the sparse MLE.

## Honesty / caveats
- **Wall-clock UNMEASURED** (no runtime). O(p) is asymptotic/structural: the
  end-to-end phylo path never inverts a dense `Cₖ` — `Q` is the O(p)-nnz tree
  precision and the per-leaf-variance rescale is folded into Z (still sparse).
  The one dense step that REMAINS is for relmat/animal components, where the
  user supplies a dense `K` (no tree to exploit) — that is inherent to the input.
- **Symbolic Cholesky reuse via `cholesky!`** is best-effort with a fresh-cholesky
  fallback; if CHOLMOD rejects the in-place update the path is still tree-sparse
  O(p) but re-analyses each eval. Correctness is identical either way.
- **Heteroscedastic gradient is analytic** but only the homoscedastic reduction is
  cross-checked algebraically against #231; the `sigma ~ x` path is anchored by the
  dense-GLS-gradient-≈0 test, not a component-wise FD-vs-analytic gate.
- **#15 scope is the pure-Julia arithmetic only** (the prior matvec). The full
  inner step still allocates O(p) inside CHOLMOD + result vectors — that is out of
  Julia's control and explicitly excluded, per the design.
- **#16 is bench/workflow_dispatch** — the exponent gate only fires with ≥3 p
  values (i.e. when p=10k is enabled); the per-PR suite only checks the generator
  + augmented-precision correctness.
