# After Task: q2/q4 Direct Export Contracts

## Goal

Split the unbanked q2/q4 bridge-export work away from the location-only REML
diagnostic PR, then make the q-series support cell explicit enough to test and
review on its own branch.

## Implemented

The bridge flattening layer now attaches private point-export payloads when a
fit has a q2 or q4 structured covariance block. q4 exports carry
`fit.ranef.Sigma_a`, axis labels, SDs, correlations, estimator, and a hard claim
boundary. q2 exports cover the exact-Gaussian residual-correlation target for
phylo, relmat, and animal formula routes, plus the direct known-covariance
fixture route used by the spatial status row.

The bivariate Gaussian formula parser now distinguishes q2 structured mean
markers from the q4 phylogenetic location-scale cell. q2 formula support is
restricted to matching `mu1` and `mu2` markers with the same structured type and
grouping variable. The q2 formula route is ML-only, complete-response only, and
requires intercept-only `sigma1`, `sigma2`, and `rho12` formulas.

## Mathematical Contract

The q2 residual-correlation cell is the complete-response exact-Gaussian model

```text
Y_i = X_i beta + u_group(i) + epsilon_i
u ~ N(0, Lambda kron K)
epsilon_i ~ N(0, D)
```

where `Lambda` is the 2 x 2 among-axis covariance for `mu1` and `mu2`, and `D`
is the 2 x 2 residual covariance carrying `rho12`. Known-covariance relmat and
animal routes invert the supplied covariance once; phylo uses the augmented-tree
precision route. Spatial is represented only as fixed-covariance fixture
evidence in the status contract, not as a range-estimating formula route.

The q4 export cell is point extraction from the existing phylogenetic
location-scale fit, not new q4 inference.

## Files Changed

- `src/bridge.jl`
- `src/coevolution_q.jl`
- `src/gaussian_bivariate.jl`
- `src/gaussian_core.jl`
- `src/DRM.jl`
- `test/test_bridge_q2_direct_export.jl`
- `test/test_bridge_q4_direct_export.jl`
- `test/test_bridge.jl`
- `test/runtests.jl`
- `docs/src/developer-notes/formula-grammar.md`
- `docs/dev-log/check-log.d/2026-06-24-q2-q4-direct-export-contracts.md`
- `docs/dev-log/after-task/2026-06-24-q2-q4-direct-export-contracts.md`

## Checks Run

```sh
julia --project=. test/test_bridge_q4_direct_export.jl
julia --project=. test/test_bridge_q2_direct_export.jl
julia --project=. test/test_bridge.jl
julia --project=. -e 'using Test, Random, LinearAlgebra, StatsModels, DRM; include("test/test_reml_q4_allaxes.jl")'
git diff --check
```

The q4 direct export test passed 36/36 assertions. The q2 direct export test
passed 116/116 assertions. The bridge boundary test passed 51/51 assertions.
The q4 REML all-axes regression passed 9/9 assertions after reverting an
unrelated attempted tightening of q4 default tolerances. `git diff --check` was
clean.

## Tests Of The Tests

The q2 and q4 status validators include malformed-row checks so schema and
target drift fail explicitly. The q2 tests also exercise rejected malformed
data, rejected unsupported spatial formula routing, relmat and animal formula
routes, the phylo residual-correlation formula route, and the older restricted
diagonal-residual coevolution fixture.

## Consistency Audit

The formula grammar page now names the exact q2 and q4 structured bivariate
cells and their exclusions. The claim-boundary strings in the export payloads
and status rows explicitly reject broad bridge support, q2/q4 REML, AI-REML,
interval reliability, and coverage.

## GitHub Issue Maintenance

No issue was edited. This branch is stacked on the updated DRM.jl PR #297 until
the location-only REML diagnostic branch is merged or retargeted.

## What Did Not Go Smoothly

The uncommitted work was initially sitting on the PR #297 branch, which made the
loconly REML PR look broader than its title and body. The fix was to push only
the clean loconly REML commit to PR #297 and move the q2/q4 export work onto a
separate branch. The first remote CI attempt also exposed that tightening q4
defaults from `1e-3` to `1e-4` was outside this slice and destabilised the q4
REML all-axes regression on CI. Those default edits were reverted; this branch
keeps q4 optimizer defaults unchanged.

## Team Learning

q-neighbour inference is dangerous. A q4 point extractor, a q2 residual route,
and a restricted diagonal-residual coevolution fixture need separate rows,
separate tests, and separate prose. Treating the support cell as the unit of
truth keeps the R and Julia bridge lanes from drifting again.

## Known Limitations

This slice does not provide broad R-via-Julia bridge support. It does not add
q2 or q4 REML, AI-REML, interval reliability, interval coverage, non-Gaussian
structured q2/q4 support, structured q6/q8 support, or spatial range estimation.
The q2 formula route requires identical mean fixed-effect designs and
intercept-only `sigma1`, `sigma2`, and `rho12` formulas.

## Next Actions

Run the full test suite or CI after the branch is pushed. Then decide whether to
open this as a stacked draft PR against PR #297 or hold it until PR #297 merges
and retarget it to `main`.
