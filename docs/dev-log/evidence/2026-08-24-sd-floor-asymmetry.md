# The two engines have different parameter-space boundaries — and that is what the
# `phylo_gamma` margin actually measures

**Date:** 2026-08-24 · **Branch:** `parity/se-axis` · **Issue:** #457
**Status:** measured. Diagnosis, not a repair. No `src/` change made.

## Provenance

W2-D (Gauss) diagnosed the `phylo_gamma` parity margin and concluded "flat likelihood
ridge near a variance-component boundary". Following that up, the boundary turns out to be
**literal and one-sided**, which sharpens the finding and generalises it beyond this cell.

## The measurement

`parity-phylo-nongaussian.tsv` records `phylo_gamma` as `PARITY_PASS` with
`loglik_diff = 2.899e-05` against `tolerance = 1e-04` — 4–6 orders looser than every
sibling. Across 8 seeds (W2-D): median `4.25e-11`, min `5.5e-12`, **max `2.899e-05` at
seed 411 only** — the committed seed. 0/8 crossed `1e-4`. Deterministic, reproducible,
not noise.

At seed 411 the two engines report different fitted phylogenetic SDs:

| engine | fitted phylo SD |
|---|---|
| drmTMB (native TMB) | `4.577e-06` |
| DRM.jl | `1.000e-06` |

`1.000e-06` is not an estimate. It is a **hard floor**:

```
src/sparse_laplace_glmm.jl:149   const _LAPLACE_LOG_SD_FLOOR = log(1e-6)
```

A search of drmTMB `origin/main` (`R/`, `src/`) finds **no equivalent lower bound** on a
phylogenetic variance component. Its floors are unrelated — a meta-analysis
`sigma_floor = max(1e-4, 0.05 * y_scale)` (`R/drmTMB.R:17023`) and an SE-inflation check
threshold (`R/check.R:767`).

## What this means

The likelihood expressions are **not** in disagreement. W2-D's same-parameter-vector test
settles that: evaluating DRM.jl's own Laplace objective at drmTMB's reported θ reproduces
DRM.jl's optimum to `7.8e-12`. No dropped constant, no Jacobian error, no penalty
mismatch.

What differs is **where each engine is allowed to stop.** On this draw the phylo variance
is near-degenerate, so DRM.jl's optimum is a *constrained* optimum sitting exactly on its
own floor, while drmTMB's is *interior*. Two different points, two different logLik values
— and because the mean-side coefficients are barely affected by a near-zero variance
component, `max_abs_coef_diff` stays at `6.3e-08` while `loglik_diff` opens to `2.9e-05`.
**That asymmetry is the signature of a boundary, not of a formula bug.**

## Consequences for the parity campaign

1. **No tolerance choice fixes this.** A comparison between an engine with a variance
   floor and one without will diverge *specifically* on near-degenerate draws, and the size
   of the divergence depends on how close the truth sits to the boundary. Tightening
   `tolerance` off a well-behaved seed would simply move the failure to a different draw.
2. **It is not confined to Gamma.** W2-D observed `phylo_beta` crossing `1e-4`
   (`1.58e-4`) under a related near-boundary draw, while its committed row reads
   `3.89e-10`. Same mechanism, different family. Any cell whose generating variance is
   small enough to approach `1e-6` is exposed.
3. **It reaches the SE axis.** A standard error taken at a constrained optimum on the
   boundary is not comparable to one taken at an interior optimum — the information matrix
   is being evaluated at a different kind of point. The SE comparator must detect and
   report boundary cases rather than silently comparing them.

## Recommendation (not executed here)

- Record the boundary status alongside each phylo parity row, so a margin can be read as
  "constrained fit" rather than "engines nearly disagree".
- Prefer fixture seeds whose variance component is well away from the floor, and say so
  explicitly rather than choosing quietly.
- Do **not** tighten `tolerance` on the strength of the well-behaved seeds.
- Open the real question separately: **should `_LAPLACE_LOG_SD_FLOOR` exist at `1e-6`?**
  It is presumably there for numerical safety in the Laplace inner problem. That is an
  engine design decision with a usability argument on both sides, and it is out of scope
  for a measurement arc — but it is now a *known, measured* difference from the R twin
  rather than an unexamined one.

## What this does NOT establish

Not a coverage claim, not an accuracy ranking, and not a defect in either engine. Both are
doing something defensible; they simply do not share a feasible set. No capability row is
promoted on this evidence.
