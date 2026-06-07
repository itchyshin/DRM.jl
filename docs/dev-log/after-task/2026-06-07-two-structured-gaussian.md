# After-task: Gaussian fit with TWO structured variance components (phylo + animal)

> **Status: UNVERIFIED in-session.** Written in a cloud session with **no Julia
> runtime** (package servers blocked). Verification is **CI-only** via the PR's
> GitHub Actions (`test (1)`, `test (1.10)`, `docs`). Do not promote any claim
> here to "verified" until those checks are green.

## Scope (NEW capability — no drmTMB parity claimed)

Comparative datasets often need BOTH a phylogenetic covariance AND an
animal/relatedness covariance as **separate** variance components on the same
Gaussian response. Until now the structured path handled one marker at a time.
This adds a focused FIRST cut for two structured intercepts in one ML fit:

```julia
drm(bf(@formula(y ~ x + phylo(1 | species) + relmat(1 | id)), @formula(sigma ~ 1)),
    Gaussian(); data, tree = phy, K = Canim)
```

Latent field = SUM of two structured effects:

    y = Xβ + Z₁a₁ + Z₂a₂ + ε,  a₁~N(0,σ₁²C₁),  a₂~N(0,σ₂²C₂),  ε~N(0,σ²I)

so the marginal stays exactly Gaussian, `y ~ N(Xβ, V)` with
`V = σ²I + σ₁² Z₁C₁Z₁ᵀ + σ₂² Z₂C₂Z₂ᵀ`. ML estimates β, σ (residual), σ₁, σ₂.

## Changes

- `src/gaussian_ranef.jl`
  - `_split_ranef` made order-stable for the single `structured` slot (keeps the
    FIRST marker; backward compatible — every non-Gaussian caller still gets a
    single tuple).
  - New `_collect_structured(rhs)` returns the full ordered list of structured
    markers (kind, grouping).
  - `vc(fit)` extended: alongside `(1+x|g)` 2×2 covariances (`:recov`), it now
    reports scalar / structured variance components (`:resd`) as named **1×1**
    variance matrices, keyed by grouping factor — so both `:species` and `:id`
    appear.
- `src/gaussian_structured.jl`
  - `_resolve_structured_matrix` — resolves one marker to its G×G matrix from the
    `K`/`A`/`tree` kwargs (spatial deferred — it estimates a range jointly).
  - `_structured_Z` — one-hot group indicator.
  - `_fit_two_structured_gaussian` — DENSE marginal Gaussian fit; θ = [βμ; logσ;
    logσ₁; logσ₂]; reports both SDs via `re_sd`/`vc`; BLUPs
    `âⱼ = σⱼ² Cⱼ Zⱼᵀ V⁻¹ r` via `ranef`.
- `src/gaussian_core.jl` — `drm(::DrmFormula, ::Gaussian)` routes to the new
  fitter when `_collect_structured` finds two markers (guards: exactly two,
  distinct grouping factors, no other RE / meta on the mean, fixed `sigma`).
- `src/summary.jl` — title for the new `:resid` block.
- `test/test_two_structured_gaussian.jl` (wired into `runtests.jl`) — seeded
  recovery of both σ₁ (phylo) + σ₂ (animal) + residual; collapse check (σ₂→0
  recovers the single-phylo fit's phylo SD and logLik, within tol); error paths
  (missing matrix, shared grouping factor).

## Honesty / caveats

- **New capability, not drmTMB parity.** No R round-trip asserted.
- **DENSE first cut.** V is assembled and Cholesky-factored at n×n each eval
  (O(n³)). Fine for the small CI fixtures (n ≤ 320); **sparse/Woodbury assembly
  is the speed follow-up** (the single-component path already uses Woodbury — the
  two-component capacitance generalises but was deferred for correctness-first).
- **Residual is `sigma ~ 1`** (homoscedastic). A `sigma ~ x` predictor (D → diag)
  is a straightforward extension, deferred.
- **Spatial** is not yet allowed as one of two components (it estimates a range
  jointly); only relmat/animal/phylo combine.
- No existing issue — propose filing one to track the sparse follow-up + a
  `sigma`-predictor extension.

## Evidence (CI to run)

PR GitHub Actions: `test (1)`, `test (1.10)`, `docs`. The recovery test asserts
σ₁≈0.9, σ₂≈0.6 (atol 0.35), residual σ≈0.35 (atol 0.1) on a seeded n=320 fixture;
the collapse test asserts `logLik(two) ≥ logLik(one) − 1e-3` and matching phylo SD.
