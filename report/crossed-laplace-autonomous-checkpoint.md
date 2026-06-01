# Crossed Laplace Autonomous Checkpoint

Branch: `codex/crossed-poisson-speed`

## Implemented

- Poisson crossed sparse-Laplace speed pass with exact implicit logdet-gradient
  correction and no finite-difference polish in the benchmark path.
- Generic internal crossed-Laplace mean engine for scalar crossed random
  intercepts, using per-family first/second/third derivatives.
- Internal family kernels:
  - Binomial logistic mean, no nuisance parameter.
  - NB2 log-mean with fixed size.
  - Gamma log-mean with fixed shape.
  - Beta logit-mean with fixed precision.
- Bench scripts:
  - `bench/profile_crossed_laplace.jl`
  - `bench/profile_inference_quick.jl`
- Reports:
  - `report/crossed-poisson-benchmark.md`
  - `report/crossed-laplace-family-profile.md`
  - `report/inference-profile-quick.md`
  - `report/laplace-speed-scout.md`

## Measured Gates

- Paired Poisson drmTMB benchmark: median R/Julia speedup 23.28x.
- Fixed-q Poisson n=20k cell: 45.43x R/Julia speedup.
- Internal family recovery test passes for Poisson, Binomial, fixed-NB2,
  fixed-Gamma, and fixed-Beta crossed random intercepts.
- Internal family profile shows Binomial and fixed-NB2 are clean on convergence;
  Gamma and Beta need convergence/status and derivative-cost work before parity
  claims.
- Crossed Gaussian profile-CI prototype:
  - Current `confint(..., method=:profile)`: 8.04 s.
  - Warm prototype: 5.82 s.
  - Threaded warm prototype on 4 Julia threads: 2.56 s.
  - Endpoint delta versus current profile CI: 0.

## Verification Run

- `git diff --check`
- `julia --project=. test/test_crossed_laplace_generic.jl`
- `julia --project=. test/test_poisson_crossed_laplace.jl`
- `julia --project=bench bench/fit_crossed_poisson.jl && Rscript bench/R/compare_crossed_poisson.R`
- `julia --project=bench bench/profile_crossed_laplace.jl`
- `julia --project=bench --threads=4 bench/profile_inference_quick.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`

## Open Items Before PR

- Decide whether to track generated crossed-Poisson fixture/result files or keep
  them generated-only.
- Rebase/merge `origin/main` because this branch is currently one commit behind.
- If public API routing expands beyond Poisson, coordinate with Shannon because
  family front-end files are not Codex's lane.
- Do not claim NB2/Gamma/Beta drmTMB speed parity yet; their current rows are
  internal fixed-nuisance engine proofs.
- No private uploaded-paper path or private manuscript reference has been added.
