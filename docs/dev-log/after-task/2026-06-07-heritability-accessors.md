# After-task: phylogenetic heritability / repeatability accessors with CIs

> **Status: UNVERIFIED in-session.** Written in a cloud session with **no Julia
> runtime** (package servers blocked). Verification is **CI-only** via PR #233's
> GitHub Actions (`test (1)`, `test (1.10)`, `docs`). Do not promote any claim
> here to "verified" until those checks are green.

## Scope

Comparative-biology headline ratios on the structured-Gaussian fits
(`phylo`/`relmat`/`animal` random intercepts, single- and two-component):

- **phylogenetic heritability / signal** `h² = σ²_component / (Σ_k σ²_k + σ²_resid)`
- **repeatability / ICC** `R = σ²_component / (σ²_component + σ²_resid)`

Each returns a point estimate **plus a CI**, two ways, reusing merged infra.

## Changes

- `src/heritability.jl` (new)
  - `_variance_component_indices(fit)` maps each grouping factor to the
    working-scale θ index carrying its `log σ` (from the `:resd` block) and the
    residual `log σ` index (from `:resid` for the two-component path, or a
    homoscedastic `:sigma` intercept for the single-component closed-form path;
    rejects a heteroscedastic `sigma ~ x`).
  - `_ratio_closure(focal, denom)` builds `g(θ) = σ²_focal / Σ σ²_k` with
    `σ²_k = exp(2 θ_k)`, so ForwardDiff differentiates EXACTLY through the
    log-σ → variance map.
  - `heritability(fit; component, level, method)` — denominator = all components +
    residual (full-variance share / phylogenetic signal).
  - `icc` / `repeatability(fit; component, …)` — denominator = focal + residual
    (two-component repeatability). With one component they coincide with
    `heritability`.
  - `method = :delta` (default) → `bias_correct` (#228): `(estimate, corrected =
    estimate + ½tr(H_g V), bias, se = √(∇gᵀV∇g), ci)`, CI **clamped to [0,1]**.
  - `method = :profile` → substitution profile on the focal `log σ`, re-evaluate
    the stored NLL, invert the LRT (`χ²₁`) by bracket-and-bisect in ratio space.
- `src/DRM.jl` — include `heritability.jl`; export `heritability`,
  `repeatability`, `icc`.
- `test/test_heritability.jl` (wired into `runtests.jl`).

## Anchors (CI-verifiable)

- **Closed-form:** `heritability(fit).estimate == σ²_phylo/(σ²_phylo+σ²_resid)`
  computed by hand from `re_sd`/`sigma`, `atol = 1e-8`, single AND two-component;
  the full partition (`h²_species + h²_id + resid_share`) sums to 1; ICC ≥ h².
- **Degenerate:** a component with no signal ⇒ `h² < 0.1`, CI lower clamped to 0;
  residual → 0 ⇒ `h² > 0.95`, CI upper clamped to 1.
- **Delta vs profile:** identical point estimate; CI endpoints agree to
  `atol = 0.12` on a well-identified n≈720 fixture.
- **Errors:** no structured components / heteroscedastic residual / ambiguous
  focal (>1 component, none chosen) throw.

## Honesty / caveats

- **Scoped** to the clean structured-Gaussian models where the variance
  components are clean scalars. Non-Gaussian Laplace routes and the q4 PLSM (a
  4×4 Λ, not a single scalar ratio) are explicitly out of scope.
- The profile is a **substitution** profile: the focal `log σ` is moved to hold
  the ratio fixed while the co-component(s) and residual stay at their MLE — cheap
  and deterministic, and it matches the delta CI on well-identified fits. A full
  constrained re-optimisation of the background under the ratio constraint is a
  heavier follow-up (would tighten agreement at extreme ratios).
- The delta SE inherits `vcov`'s behaviour at a singular variance boundary; the
  `:profile` method is preferable there (and the CI is clamped either way).
- The bias-corrected value can stray marginally outside [0,1] under heavy
  curvature; it is reported as-is (honest) while the CI is always clamped.

## Evidence (CI to run)

PR #233 GitHub Actions: `test (1)`, `test (1.10)`, `docs`. See
`test/test_heritability.jl` for the anchors and tolerances above.
