# gllvmTMB/GLLVM.jl lessons for the DRM.jl R bridge

Date: 2026-06-08

This note records what the gllvmTMB/GLLVM.jl pair is doing well and what DRM.jl
should copy when measuring `drmTMB(..., engine = "julia")`. It is a source audit
and planning note, not a new bridge timing result.

Current local blocker:

```text
JuliaCall installed: FALSE
```

So the R bridge timing table still needs a JuliaCall-enabled R library before it
can be measured honestly.

## What GLLVM has already made credible

| Surface | Local evidence | Why it matters for DRM.jl |
|---|---|---|
| Gaussian reduced-rank GLLVM | `GLLVM.jl/docs/src/benchmarks.md` compares R `gllvmTMB` and GLLVM.jl on the same simulated data and the same Gaussian marginal log-likelihood. Six cells x three reps x two engines all converged. Median speedups run from 161.2x to 698.1x, with worst `abs(Delta logLik) = 2.343e-07`. | The speed claim is paired with an agreement gate. DRM should never report "Julia is faster" without the corresponding likelihood, coefficient, and fitted-value parity checks. |
| Warm benchmark caveats | `GLLVM.jl/docs/src/comparison.md` states that both engines get warm-up passes and that publishable claims need more reps plus a cold-start row. | DRM bridge benchmarks should report cold bridge startup, warm bridge refit, and pure Julia kernel time as separate rows. |
| Exact model boundary | `GLLVM.jl/docs/src/comparison.md` distinguishes the exact GLLVM comparison from the MixedModels proxy LMM. | DRM should label each timing row as one of: byte-identical model, closest R analogue, or standalone Julia kernel. |
| Sparse phylo representation | `gllvmTMB/R/gllvmTMB.R` recommends `tree =` inside `phylo_*()` terms and builds sparse `A^-1` over tips plus internal nodes with `MCMCglmm::inverseA(tree)`, about `5n` nonzeros instead of dense `n^2`. The dense `vcv =` route is explicitly superseded. | DRM/drmTMB should treat tree input as the main path and dense tip covariance as compatibility. Large examples should not be timed on the dense tip-covariance path. |
| Sparse phylo scaling | `GLLVM.jl/docs/src/benchmarks.md` reports the node-frame analytic gradient scaling roughly linearly to `p = 10000`, with the single-axis branch using same-leaf Takahashi selected inverse. | The 9993-tip AVONET/Hackett example is the right DRM speed target, but it must use the sparse all-node route on both sides where possible. |
| Engineering discipline | `gllvmTMB/docs/design/43-asreml-speed-techniques.md` ranks sparse `A^-1`, starts, sparse Cholesky checks, and OpenMP by expected payoff instead of chasing every possible optimizer. | DRM should decide defaults by model class and measured bottleneck: Gaussian closed-form/EM where it is enough, sparse TMB-like/Laplace or sparse information routes where uncertainty and non-Gaussian support require them. |

## What DRM.jl should copy

The main lesson is not only "Julia can be faster". The lesson is evidence
organisation.

DRM should keep four timing layers separate:

1. **Pure Julia kernel**: direct `DRM.drm(...)` timing with no R bridge. This is
   where current AVONET/Hackett and bootstrap evidence lives.
2. **R bridge warm timing**: `drmTMB(..., engine = "julia")` after Julia is
   initialized and method specialisations have compiled.
3. **R bridge cold timing**: first call in a fresh R session, including
   JuliaCall setup and package load.
4. **Native TMB comparator**: `drmTMB(..., engine = "tmb")` on the same R data,
   same formula, same tolerance policy, and same inferential target.

Every table should include more than time:

- `n`, and for phylo models, number of tips and all-node states;
- route label: `byte_identical`, `closest_analogue`, or `standalone_kernel`;
- convergence flags from both engines;
- log-likelihood difference;
- fixed-effect coefficient difference;
- scale/random-effect parameter difference;
- fitted-value or residual-summary difference where available;
- cold/warm status;
- Julia, R, TMB, and package versions.

This is how we avoid mixing a real bridge claim with a standalone Julia claim.

## Direct bridge benchmark plan

Once JuliaCall is available, the first live bridge table should be small but
strict:

| Benchmark | R formula | Engines | Pass condition |
|---|---|---|---|
| Fixed-effect Gaussian | `growth ~ temperature`, `sigma ~ 1` | TMB vs Julia bridge | Same logLik within tolerance, same coefficients, warm timing recorded for `n = 100, 1000, 10000`. |
| Gaussian phylo smoke | `growth ~ temperature + phylo(1 | species, tree = tree)`, `sigma ~ 1` | TMB sparse tree route vs Julia bridge sparse tree route | Both use tree/sparse representation. Report `n = 100, 1000`, then AVONET/Hackett 9993 only after smoke parity passes. |
| Repeated-refit CI path | Same AVONET/Hackett model | Julia direct, Julia bridge, native TMB where feasible | Bootstrap/profile rows report `B`, workers, failures, interval target, and elapsed time. |

The high-value speed story is probably not ordinary fixed-effect Wald intervals.
Those should be cheap once the information matrix is available. The stronger
story is repeated fitting for variance-component or random-effect uncertainty:
profile likelihood and parametric bootstrap can reuse the sparse phylo machinery
many times, and that is where Julia threading should matter.

## Current DRM.jl evidence to connect next

The current direct Julia AVONET/Hackett benchmark lives in
`report/avonet-phylo-gaussian-algorithms.md`.

That report is deliberately not an R bridge table. It shows:

- full real tree/data example: 9993 tips, 19985 all-node states;
- current `algorithm = :auto` sparse EM route;
- `g_tol = 1e-4` fit in 0.790 seconds on the local warm run;
- B = 20 bootstrap serial/threaded comparison: 34.860 seconds serial versus
  10.811 seconds threaded on four Julia workers, a 3.22x speedup on the
  simulated-refit phase;
- missing inference pieces: finite `vcov`, attached `nll`, and profile support
  for the EM route.

The next DRM bridge slice is therefore:

1. install or activate JuliaCall in the R library used by drmTMB checks;
2. run the fixed-effect Gaussian bridge table first, because it is the cleanest
   byte-identical smoke test;
3. run the phylo bridge table only after the R side passes tree objects through
   to Julia and both engines are using sparse tree representations;
4. add the AVONET/Hackett 9993 row after the 100 and 1000 species parity rows
   pass;
5. put bootstrap/profile timing behind the same bridge once finite inference
   plumbing is available.

## Practical default lesson

For DRM.jl, "default algorithm" should probably be conditional, not one global
answer:

- Gaussian fixed-effect or simple Gaussian structured models: use the fast
  closed-form/EM-style Julia route when it returns the needed inference objects.
- Large Gaussian phylo models from a tree: default to sparse all-node tree
  machinery; do not silently fall back to dense tip covariance.
- Non-Gaussian and profile-heavy workflows: keep a TMB-like sparse
  likelihood/gradient route available, because it is more general for Laplace
  approximation, profiles, Hessians, and uncertainty accounting.

That is the thing to learn from GLLVM: make the fast path real, but keep the
agreement gates and inference route explicit enough that speed does not outrun
the statistical contract.
