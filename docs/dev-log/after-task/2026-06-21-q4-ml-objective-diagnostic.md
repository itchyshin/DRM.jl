# After-task: q4 ML objective diagnostic for #293

## Purpose

Issue #293 needs the Ayumi q4 ML failure to stop collapsing into the single
surface symptom `logLik = -Inf`. This slice adds a direct DRM.jl diagnostic for
the q4 ML Laplace objective so a failing `theta` evaluation can name the first
non-finite component.

This is diagnostic hardening only. It does not claim that the 10,440-tip Ayumi
route is fixed, fast, or interval-ready.

## Changes

- Added `q4_marginal_diagnostic(prob, Q_cond, theta; u0, n_newton, gradient)` in
  `src/fit_q4_sparse_tmb.jl`.
- The helper evaluates the same pieces used by `marginal_nll`, in order:
  `theta`, among-axis covariance, among-axis Cholesky, prior precision, inner
  mode, `logdet_H`, joint NLL at the mode, `logdet_P`, Laplace log-likelihood,
  marginal NLL, and optionally the exact-gradient assembly.
- The return value is a NamedTuple with `ok`, `first_nonfinite`, `stages`,
  `nll`, and `loglik`.
- Added `test/test_q4_objective_diagnostic.jl` and wired it into
  `test/runtests.jl`.

## Evidence

Focused diagnostic test:

```sh
julia --project=. -e 'using Test, DRM; include("test/test_q4_objective_diagnostic.jl")'
```

Result: 10/10 passed.

Adjacent q4 engine checks:

```sh
julia --project=. -e 'using Test, DRM; include("test/test_coverage_engine.jl"); include("test/test_q4_objective_diagnostic.jl"); include("test/test_reml_q4_allaxes.jl")'
```

Results:

- `test/test_coverage_engine.jl`: 23/23 passed.
- `test/test_q4_objective_diagnostic.jl`: 10/10 passed.
- `test/test_reml_q4_allaxes.jl`: 9/9 passed.

Bridge-facing q4 inference smoke:

```sh
julia --project=. -e 'using Test, DRM; include("test/test_bridge_bivariate_inference.jl")'
```

Result: 22/22 passed in 2m45.5s, with the expected REML AIC warning.

Direct synthetic q4 ML probe:

- A direct DRM.jl synthetic one-observation-per-species q4 probe at p = 30,
  100, and 250 returned finite converged ML fits.
- Therefore the observed Ayumi ML `-Inf` ladder is not a generic p-size failure
  of the synthetic q4 path.
- The private Ayumi bundle was not present at `/private/tmp/ayumi-for-test` or
  `/tmp/drmtmb-ayumi-evidence` in this environment, so the real 100/250/500-tip
  direct replay is still pending.

## Rose Audit

- Scope stayed within the q4 ML diagnostic surface and a direct unit test.
- No fitting defaults, optimizer gates, REML objective, formula grammar, bridge
  semantics, public Ayumi reply, or speed claim changed.
- This does not close #293. It supplies the first-non-finite component reporter
  needed before the private Ayumi bundle is replayed directly inside DRM.jl.

## Claim Boundary

REML remains Gaussian-only. This diagnostic does not make Julia ML usable at
Ayumi scale, does not make Julia faster, and does not support a 10k q4
sigma-phylo interval claim.
