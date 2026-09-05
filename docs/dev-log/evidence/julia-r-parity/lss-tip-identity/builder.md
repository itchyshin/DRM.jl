# LSS phylogenetic tip identity — builder gate

## Contract

For the Gaussian `sd(species, phylogenetic)` location-scale-scale frontend,
the random-effect index is the tree's leaf order, never first appearance in the
observation rows.  Integer labels mean positional tips `1:p`; non-integer
labels must exactly match `AugmentedPhy.leaf_names`.  The full input must
contain every tree tip before a missing response is filtered, so a tip with
only missing responses remains a prior-only tree state.  Unknown or missing
group labels, and an absent tree tip, are errors.  IID `sd(group)` continues to
use its existing first-seen grouping convention.

Both the dedicated phylogenetic LSS frontend and the phylogenetic component of
the multi-component LSS frontend use this rule.  Supported tree inputs are an
`AugmentedPhy` or Newick string; other providers are not qualified by this
slice.

## TDD command

The focused fit estimate is below 120 seconds on one Julia and one BLAS thread.
Retain full output as `red-001.log` before the source repair and `green-001.log`
after it; stop and report if the command exceeds that limit.

```sh
cd /private/tmp/drm-parity-20260830/DRM.jl
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. \\
  -e 'include("test/test_lss_tip_identity.jl"); println("LSS_TIP_IDENTITY_PASS")'
```

The normal suite retains known small-fixture variance-boundary comparisons as
explicit broken tests.  The required strict numerical gate must instead run
the same comparisons as ordinary tests and is expected to fail until the
optimizer branch is repaired:

```sh
cd /private/tmp/drm-parity-20260830/DRM.jl
DRM_LSS_STRICT_BOUNDARY=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. \\
  -e 'include("test/test_lss_tip_identity.jl"); println("LSS_TIP_IDENTITY_STRICT_PASS")'
```

## Independent checks

The test computes the Gaussian marginal likelihood from the named tree
correlation, residual-scale coefficients, and group-SD coefficients.  It checks
that likelihood to `1e-7` and shuffled-versus-tip-ordered coefficients to
`4e-6`.  It exercises dedicated dense and sparse routes, the multi-component
IID-plus-phylogenetic route, ML, REML, one wholly missing response tip, Newick
input, and error neighbours.  This is a frontend identity repair, not a sparse
numerical-engine, performance, inference, or arbitrary-row prediction claim.
