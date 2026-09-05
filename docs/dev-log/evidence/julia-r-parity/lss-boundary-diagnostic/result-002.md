# Six-tip LSS boundary diagnostic — run 002

> Historical reconstructed-fixture run.  It used the hard correlation matrix
> to generate `y`, so it is retained for runner development only.  The
> source-fixture result is [`result-005.md`](result-005.md), whose inputs are
> byte-verified against the original test helper without executing testsets.

**Command.**

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. tools/lss_boundary_diagnostic.jl
```

The command was run under a 180-second watchdog and completed in 18.34 seconds
on one Julia thread and one BLAS thread.

| input | SHA-256 |
| --- | --- |
| `src/gaussian_lss.jl` | `4465956f8786436b72827366032178f1a81f0b76582df7f232d155ed624191f9` |
| `test/test_lss_tip_identity.jl` | `9e8f2522841c1294d4cfac6aa11d26fe7c8bd2b1c6d501f2fe22b8391e283068` |
| runner | `926ab3d71395d3bd1f93eff98011001984d50c7b0d92daa09f5a64bc00b99c23` |

The runner constructs its response and covariance oracle from the hard-coded,
asymmetric six-tip correlation matrix.  It does not import the test file or
call `DRM._phylo_correlation` for its oracle.  At each fitted theta its
independent named-covariance negative log likelihood agreed with the stored
objective within `1.5e-14`.

## Dedicated phylogenetic LSS

The two fitted objectives differ by `2.13e-14`; either order's objective at
the other order's theta is `6.969445879520087`.  Score infinity norms are
`3.02e-9` and `1.44e-8`.  The `mu` and `sigma` block differences are at most
`3.73e-11` and `3.18e-11`, respectively.  The `sd_phylo` block differs by
`0.201440843` in the runner's two valid optimisation paths.

The fitted phylogenetic log-SD blocks are `[-36.17252825, -12.92849549]` and
`[-35.97108740, -12.85346530]`.  Their Hessian diagonal entries are approximately
`4e-18` to `6e-18`; the directed curvature between the two `sd_phylo` blocks is
`1.16e-18`.  The five-point interpolation has unchanged displayed objective
values.  The independently rebuilt phylogenetic covariance contribution has
Frobenius fraction `1.14e-18` and `1.44e-18` of the total covariance, with a
relative difference `3.05e-19`.

## Multi-component scalar-phylogeny LSS

The two objectives differ by `1.42e-14`; cross-order evaluations are
`1.8134460868339701` and `1.8134460868339772`.  Score infinity norms are
`6.51e-8` and `5.00e-9`.  The `mu`, `sigma`, and IID `sd` blocks agree within
`4.66e-10`, `4.66e-10`, and `1.50e-9`; `sd_phylo` differs by `1.670844818`.

The fitted phylogenetic log-SD values are `-21.05978267` and `-22.73062749`.
Their Hessian diagonal entries are `2.48e-16` and `8.77e-18`, and the directed
curvature is `2.48e-16`.  The phylogenetic contribution is `1.51e-17` and
`5.36e-19` of total covariance, with relative between-order difference
`1.46e-17`.  The IID component remains material (`0.538` Frobenius norm) and
agrees between orders.

## Interpretation and remaining gate

This records **observed small phylogenetic covariance contributions and flat
log-SD coordinates** in this reconstructed fixture: the objectives and
independent named covariances remain invariant while the raw phylogenetic
log-SD coordinates vary.  The package's covariance guard also reported
singular Hessians and pseudo-inverse covariance estimates for all four fits.
Because the variance parameterisation is `exp(2a)`, derivatives in the raw
log-SD coordinate necessarily shrink as the component approaches zero; this
evidence alone does not prove structural non-identifiability or a general
optimizer cause.  It also does not make covariance agreement a substitute for
the required raw-theta `4e-6` parity gate.

The retained strict test remains open.  Its prior strict run selected other
raw log-SD coordinates (including max raw differences `4.529800948` and
`0.861068016`); run 002 does not correct or waive that failure.

## Retained failed first runner invocation

`run-001.log` is retained.  It failed before completing the diagnostic because
the runner used unavailable `eigvalsh`; it emitted the first fit's existing
singular-Hessian warning before that tool-only error.  The runner was corrected
to use `sort(eigvals(Symmetric(...)))`; no DRM source or test file changed.
