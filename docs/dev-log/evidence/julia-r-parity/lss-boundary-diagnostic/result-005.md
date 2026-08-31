# Six-tip LSS boundary diagnostic — byte-verified source fixture

## Execution and provenance

Run 005 used the default `original-test-bytes` mode:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. tools/lss_boundary_diagnostic.jl --fixture=original-test-bytes
```

It ran beneath a 90-second watchdog and finished in **19.41 seconds**.  It
reported `Threads.nthreads() = 1`, `OPENBLAS_NUM_THREADS = 1`, and
`BLAS.get_num_threads() = 1`.

The runner evaluates only the definition prefix of
`test/test_lss_tip_identity.jl`, through the first `@testset` marker.  It does
not execute a testset.  For both shuffled and ordered data it then verified
byte equality (`isequal`) for `labels`, `y`, `x`, `z`, `study`, `species`,
`species_idx`, and `z_tip` against a separately reconstructed copy using the
same `DRM._phylo_correlation` call as the test.  The hard-coded asymmetric
correlation matrix remains confined to the independent covariance and
likelihood oracle.

| input | SHA-256 |
| --- | --- |
| `src/gaussian_lss.jl` | `4465956f8786436b72827366032178f1a81f0b76582df7f232d155ed624191f9` |
| `test/test_lss_tip_identity.jl` | `9e8f2522841c1294d4cfac6aa11d26fe7c8bd2b1c6d501f2fe22b8391e283068` |
| runner | `5e31621da5192ee7fd20dc5284d304608055932c882eb633505f560e32d7abbf` |

The complete `src/` and runner/test manifests before and after this run are
retained as `*-before-run005.sha256` and `*-after-run005.sha256`.  Both
manifest diffs are empty.  `inference.jl` was not called by the likelihood
diagnostic; its concurrent development is therefore excluded from the
likelihood interpretation, while the full source manifest records that no
on-disk source bytes changed during this invocation.

## Exact retained pairs

The independent hand-matrix likelihood agreed with each stored `fit.nll` to at
most `1.4e-14`.  These checks are not a replacement for raw-coefficient parity:
they establish that the covariance mapping and objective are permutation
invariant at the reported points.

| pair | own objective difference | cross-order objective range | max raw theta difference |
| --- | ---: | ---: | ---: |
| dedicated phylogenetic LSS | `7.11e-15` | `6.969445879520087`–`6.969445879520109` | `4.5298009477` |
| multi-component scalar phylogeny | `7.11e-15` | `1.813446086833956`–`1.813446086833977` | `0.8610680164` |

The dedicated pair's `mu` and `sigma` maximum block differences are
`1.16e-9` and `2.56e-9`; its differing `sd_phylo` blocks are
`[-29.79931027, -10.55467824]` and `[-34.32911122, -12.24188236]`.
The multi pair's `mu`, `sigma`, and IID `sd` maximum block differences are
`1.50e-10`, `7.39e-11`, and `7.96e-10`; its `sd_phylo` values are
`-22.73062810` and `-21.86956008`.

## Curvature and covariance observations

For the dedicated pair, the two `sd_phylo` Hessian diagonals range from
`3.34e-17` to `8.48e-15`; the directional Hessian along the between-order
`sd_phylo` displacement is `2.15e-15`.  The five point interpolation changes
the displayed objective by at most `7.11e-15`.  Its phylogenetic covariance
contribution has Frobenius fractions `2.10e-15` and `1.00e-17` of total
covariance.  The phylogenetic-only relative covariance difference is
`2.09e-15`.

For the multi pair, `sd_phylo` Hessian diagonals are `8.77e-18` and
`4.91e-17`, with directed curvature `8.77e-18`; the interpolation reports no
displayed objective change.  Its phylogenetic contribution has fractions
`5.36e-19` and `3.00e-18`; the phylogenetic-only relative difference is
`2.46e-18`.  The IID component remains material (Frobenius norm about `0.538`)
in both orders.

All four fits emitted the existing singular-Hessian/pseudo-inverse warning.
Their reported reciprocal conditions span `5.98e-20` to `1.13e-17`.

## Interpretation and remaining gate

The source fixture shows **small phylogenetic covariance contributions and
flat raw log-SD coordinates** while the named covariance and objective remain
permutation invariant.  This is evidence relevant to the two retained strict
failures.  It is not a proof of structural non-identifiability: for
`v = exp(2a)`, first and second derivatives in raw `a` shrink automatically as
the component approaches zero.  No general optimizer cause or natural-scale
one-sided boundary score is asserted here.

The required raw-theta `4e-6` gate therefore remains open.  Covariance/objective
agreement is not substituted for it, and no source, test, optimizer, or
tolerance was changed by this diagnostic.

## Retained runner development failures

- `run-001.log`: unavailable `eigvalsh` name after the first fit warning.
- `run-003.log`: dynamic-fixture world-age call.
- `run-004.log`: incomplete reconstructed metadata in the byte-comparison
  helper.

Each is a retained runner-only failure.  `run-005.log` is the successful,
byte-verified source-fixture record.
