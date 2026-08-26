# #498 — the Julia-version-dependent collapse does not exist

**Date:** 2026-08-25 · **Host:** Totoro (`OPENBLAS_NUM_THREADS=1`) · **Branch:** `fix/498-stable-rng`

## Claim under test

#498 reported that Poisson phylo Laplace fits collapse (`σ̂ ≈ 3e-04` against truth 0.45) on Julia 1.12
but not on 1.10, with identical package versions — implying version-dependent numerical behaviour in
`src/`.

## Finding: the comparison was never like-for-like

`Random.MersenneTwister` / `dSFMT_jll` is **not stream-stable across Julia 1.10 → 1.12**. `_cr_phylo_draw(450)`
therefore generated a *different synthetic dataset* on each version. The two sides were never fitting
the same data.

## Evidence 1 — StableRNG makes the draw version-independent

Same generator, `StableRNG(seed)` in place of `MersenneTwister(seed)`, same checkout, only Julia differs:

| seed | Julia 1.10.10 | Julia 1.12.6 |
|---|---|---|
| 450  | `sum(y)=44`  `sum(x)=-2.632124834236`  hash `b3e4c84276be0d43` | **identical** |
| 4501 | `sum(y)=99`  `sum(x)=-0.413390183025`  hash `ea8a93f17dcfee41` | **identical** |
| 4502 | `sum(y)=116` `sum(x)=7.687878927301`   hash `4cbf13364831e02`  | **identical** |

## Evidence 2 — on identical data the FITS agree to 10 significant figures

| seed | Julia 1.10.10 σ̂ | Julia 1.12.6 σ̂ | agree |
|---|---|---|---|
| 450  | `2.9550078389e-04` | `2.9550078389e-04` | all 10 digits |
| 4501 | `3.5736721796e-01` | `3.5736721796e-01` | all 10 digits |
| 4502 | `2.9442781693e-01` | `2.9442781693e-01` | all 10 digits |

## Conclusion

1. **There is no version-dependent numerical behaviour in the fitting code.** The engine gives bit-comparable
   answers on both versions when given the same data.
2. **Seed 450's collapse is a property of that dataset**, not of Julia. Under StableRNG it now appears on
   **1.10 as well** — the local Mac run (Julia 1.10.0) reports `σ_ml = 2.955e-04` on the same draw.
   What is underneath is a genuine small-`ntip` **boundary MLE** on an unlucky draw; the optimiser found the
   right answer for that data.
3. **`_LAPLACE_LOG_SD_FLOOR` was never relevant.** σ̂ ≈ 3e-04 sits two orders *above* the floor, and no floor
   or clamp in `src/` could or should change a correct boundary MLE.

## Scope of the defect beyond this file

`MersenneTwister` appears in **20+ test files**. It is only a defect where a test compares results across
Julia versions, or pins an expectation to an exact draw; tests asserting statistical direction on a freshly
drawn sample are unaffected. **This change is scoped to the Cox–Reid generators (the #498 site).** A blanket
swap would silently re-draw every seeded dataset in the suite and invalidate recorded expectations — it
should be done deliberately, file by file, not as a sweep.

## Not tested

Whether the boundary MLE on seed 450's draw would also arise under exact integration (rather than Laplace).
That is a separate question from #498 and remains open.

## Reproduce

```bash
ssh totoro "cd ~/drm_coverage/DRM.jl && export OPENBLAS_NUM_THREADS=1; \
  for V in +1.10.10 +release; do ~/.juliaup/bin/julia $V --project=test --startup-file=no /tmp/xver.jl; done"
```
