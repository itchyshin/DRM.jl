# After-task: crossed sparse-Laplace fused family derivatives (#113)

## Slice

Issue: #113, under umbrella #80.

Reduced wall-clock in the generic crossed non-Gaussian sparse-Laplace path by
fusing per-observation derivative work. The objective and exact implicit-gradient
contract are unchanged.

## What changed

- Added fused helpers for:
  - mode-loop first/second derivatives;
  - value + first/second/third mean derivatives;
  - value + mean derivatives + nuisance derivatives.
- Specialised the fused path for Binomial, NB2, Gamma, and Beta.
- Kept Beta auxiliary data backward-compatible with existing tests while caching
  `digamma(precision)` in the production aux objects.
- Updated the family profile runner/report to document derivative fusion.
- Added `report/crossed-laplace-autoresearch.md` with measured baseline vs
  fused timings.

## Verification

Commands run locally:

- `julia --project=. test/test_crossed_laplace_generic.jl`
- `julia --project=. test/test_poisson_crossed_laplace.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- `julia --project=bench bench/profile_crossed_laplace.jl`
- `julia --project=bench bench/gen_crossed_family.jl`
- `julia --project=bench bench/fit_crossed_family.jl`
- `Rscript bench/R/fit_crossed_family.R`
- `Rscript bench/R/compare_crossed_family.R`

Results:

- Crossed generic + exact-gradient tests passed.
- Full `Pkg.test()` passed. Existing warnings remain: project/manifest resolve
  notice and the pre-existing `rtnb` overwrite warning in tests.
- CPU-aware family profile passed with all convergence flags true.
- Paired drmTMB benchmark passed the successful Poisson/NB2 parity gates.

## Measured speed evidence

Autoresearch profile:

- Medium Beta: `1.5885s` baseline -> `0.3370s` fused (`4.71x`).
- Medium NB2: `0.1813s` baseline -> `0.1489s` fused (`1.22x`).
- Medium Gamma: `0.1703s` baseline -> `0.1409s` fused (`1.21x`).
- Large Gamma: `0.6300s` baseline -> `0.4815s` fused (`1.31x`).

Paired drmTMB report:

- Successful Poisson/NB2 cells now show `41.52x` median R/Julia speedup
  (range `25.53x` to `175.16x`).
- Medium NB2 is `175.16x` faster (`15.2040s` R median vs `0.0868s` Julia
  median).

## Claim guardrails

- This is an exact-evaluator speed improvement, not a new approximation backend.
- Poisson is effectively unchanged because it uses its specialised crossed path.
- drmTMB still rejects the crossed Binomial/Gamma/Beta cells used in the internal
  Julia profile; those remain internal engine evidence, not R-parity claims.
- No private uploaded paper or non-public manuscript material was referenced.
