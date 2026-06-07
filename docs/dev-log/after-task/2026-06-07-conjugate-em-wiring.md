# After-task: wire the conjugate-EM solver into the public API

Issue: #12

Date: 2026-06-07

## Summary

The sparse O(p) conjugate-EM fitter for the Gaussian phylogenetic-MEAN model
(location-only, constant residual scale) is now an **opt-in** algorithm reachable
from the public `drm(::DrmFormula, ::Gaussian; ...)` API via a new `algorithm`
keyword. It is no longer experimental-only.

## What changed

- **Promoted** `src/experimental/location_only.jl` → `src/location_only.jl`.
  - Kept the EM math byte-for-byte: `LocOnlyProblem`, `make_loc_problem`, the
    Woodbury helpers (`build_M`, `Vinv_mul`, `logdetV_val`), `marginal_loglik`,
    the exact Takahashi traces (`exact_traces`), and `em_fit`.
  - **Dropped** the experimental-only bits not needed for wiring: the LBFGS
    fitter (`lbfgs_fit`), the synthetic data generator (`gen_loc`), the
    `main()`/`println` gate script, and the duplicate `include`s of
    `sparse_phy.jl` / `takahashi_selinv.jl` (already loaded by the verified core
    engine include chain).
  - **Added** `_fit_structured_gaussian_em`, a front-end adapter that builds a
    `DrmFit` with the *same shape* as `_fit_structured_gaussian`
    (`:mu`, `:sigma`, `:resd` blocks) so every accessor works.
- **Included** `src/location_only.jl` in `src/DRM.jl` immediately after
  `gaussian_structured.jl` (after all its deps).
- **Added** an `algorithm::Symbol = :auto` kwarg to the Gaussian `drm` path:
  - `:auto` (default) — **exactly today's behaviour** (GLS/LBFGS per cell).
  - `:gls` / `:lbfgs` — accepted aliases of the current default fitters.
  - `:em` — conjugate EM, dispatched **only** for the supported cell: Gaussian,
    a single `phylo(1 | g)` structured mean random effect (with `tree`), and a
    constant residual scale (`sigma ~ 1`, no σ random effect, no extra RE/meta).
    Any other cell raises a specific `ArgumentError`; an unknown algorithm symbol
    is rejected up front.
- **Docstring** for the `algorithm` kwarg on `drm(::DrmFormula, ::Gaussian)`.
- **Tests** `test/test_conjugate_em.jl` (wired into `test/runtests.jl`).

## Correctness anchor

On a seeded Gaussian phylo-mean fixture the `:em` fit recovers the SAME μ
coefficients, residual σ, and marginal logLik as the default `:auto` fit
(`rtol = 1e-3`). This is the contract that matters: same MLE, different (faster)
route. The test also checks that `:em` errors cleanly on unsupported cells
(non-constant σ, no structured RE, a plain `(1 | g)`, an unknown algorithm) and
that the accessors / `show` run on the EM fit.

## Caveats / honest notes

- **The ~3.1× speedup is previously-measured**, not re-measured in this change
  (report/comparison-grid.md §4: EM vs LBFGS at p=200/1000, same MLE). No new
  benchmark was run; there is no local Julia in this environment.
- **No coefficient vcov** from EM. The closed-form M-steps produce no outer
  Hessian, so `vcov(fit)` is filled with `NaN`s (documented in the docstring and
  asserted in the test). For Wald inference, refit with `algorithm = :auto`.
- **Phylo-variance scale differs.** The default GLS fit parametrizes the phylo
  random effect as `σ_s² · K` (K the leaf *correlation* matrix); the EM uses
  `σ²_phy · Σ_phy` (Σ_phy the root-conditioned Brownian *covariance*, diagonal
  ≠ 1). The two agree on β / residual σ / logLik, but their phylo-variance
  parameters live on different scales — `re_sd(fit)` under `:em` reports the EM's
  Brownian phylo SD `σ_phy`. This is why the correctness anchor is logLik + β +
  residual σ, not the raw phylo variance.

## Verification

- **CI only** (no local Julia/R here, package servers network-blocked): verified
  by pushing the branch and opening a PR against `main`, then reading the
  `docs`, `test (1)`, `test (1.10)` job results.

## Rose audit

- MIT-clean: this is fresh Julia wiring of code already in `src/experimental/`;
  no drmTMB GPL source vendored, no private paper used.
- Default behaviour is unchanged: `:auto` routes exactly as before; the verified
  q=4 engine is untouched.
- The `:em` path is narrowly gated to its supported cell with explicit errors.
