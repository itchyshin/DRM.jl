# After-task: direct Julia Big 4 companion-gate smoke

## Scope

Run a focused direct-DRM.jl smoke from a clean worktree after drmTMB PR #634
banked the native R/TMB Big 4 diagnostic evidence and drmTMB PR #635 named the
next companion gates. This slice checks existing direct Julia surfaces that are
adjacent to the current finish plan: fixed-effect binomial, fixed-effect
skew-normal, q4 among-axis SD profile/bootstrap inference, q4 REML all-axes
correction, and the DRM.jl bridge-inference primitive.

This is evidence-only. It does not change code, documentation APIs, formula
grammar, or bridge admission.

## Worktree

- Path: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`
- Branch: `codex/direct-julia-big4-gate`
- Base: `origin/main`
- Tested code commit:
  `9bdea6564661e1d9eb454ed3c6d2d9398522f74f Fix q4 bridge vcov and bootstrap refits (#292)`
- Julia: 1.10.0

The saved user checkout at
`/Users/z3437171/Dropbox/Github Local/DRM.jl` was dirty on
`shannon/ayumi-integration`, so this work used a fresh worktree.

## Commands

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'

julia --project=. -e 'using DRM, Test, Random, LinearAlgebra; include("test/test_binomial.jl"); include("test/test_skewnormal.jl"); include("test/test_profile_sigma_a.jl"); include("test/test_bootstrap_sigma_a.jl"); include("test/test_reml_q4_allaxes.jl"); include("test/test_bridge_bivariate_inference.jl")'
```

## Results

- `test/test_binomial.jl`: cbind route 5/5 and Bernoulli route 6/6 passed.
- `test/test_skewnormal.jl`: fixed-effect skew-normal recovery 7/7 passed.
- `test/test_profile_sigma_a.jl`: q4 among-axis SD profile CIs 20/20 passed.
- `test/test_bootstrap_sigma_a.jl`: q4 among-axis SD bootstrap CIs 36/36
  passed.
- `test/test_reml_q4_allaxes.jl`: q4 REML all-axes correction 9/9 passed.
- `test/test_bridge_bivariate_inference.jl`: DRM.jl bridge-inference primitive
  for bivariate q4 among-axis SD CIs 22/22 passed.

The q4 REML test emitted the expected AIC-on-REML warning from the
model-selection guard.

## Boundary

This is direct DRM.jl smoke/status evidence only. It does not promote
drmTMB Julia-via-R parity, direct/native Big 4 parity, q2/q4/q8 coverage,
power, recovery accuracy, release readiness, CRAN readiness, selectable
Julia-side control surfaces, or non-Gaussian REML/AI-REML. The next companion
gate remains separate Julia-via-R registry/parity evidence in `drmTMB`.
