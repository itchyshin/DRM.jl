# Ayumi's M-ladder through `engine = "julia"` — cross-engine check

Simulated 200-species clade (family-scope size), one row per species, quadratic climate in the mean,
temperature on the phylogenetic scale, precipitation on the residual scale. Both engines, same data.

| model | mu | sigma | sd(species, phylogenetic) | julia logLik | tmb logLik | Δ |
|---|---|---|---|---|---|---|
| M2  | quad climate + phylo | ~1 | ~1 | -98.5825 | -98.5825 | **0** |
| M3  | quad climate + phylo | ~1 | temp + prec | -76.9838 | -76.9838 | **0** |
| M5  | quad climate + phylo | temp + prec | ~1 | -85.7706 | -85.7706 | **0** |
| M6  | quad climate + phylo | temp + prec | temp + prec | -61.7599 | -61.7599 | **0** |
| M6q | quad climate + phylo | quad climate | quad climate | -57.9753 | -57.9753 | **0** |

Every cell agrees to the printed precision (Δ = 0.000000), so AIC/ΔAIC and the LRT comparisons the
protocol runs are engine-invariant on this ladder.

## Speed — currently the wrong way round

Warm medians, M6, n = 200: **julia 1.52 s vs tmb 1.24 s (0.81x)**. The lss engines are DENSE
(O(n^3) per likelihood evaluation) because correctness came first; that decision is what produced
7-significant-figure parity and uncovered #548. The sparse O(p) spine is issue #551 and is the
critical path for the whole-tree scope (~10^4 species), which the dense route cannot run at all
(hard-capped at 5000 rows with an explicit message).

Routes that already sit on the sparse spine win 14/15 cells at 2.3x-42x, so the gap is the missing
engine, not the language.

## Inference from R (64-tip fixture, `engine = "julia"`)

- Wald: `summary()` / `confint()` on all three blocks.
- Profile CI on `fixef:sd_phylo:x`: **1.4 s**, `conf.status = profile`, non-boundary.
- Parametric bootstrap R = 199: **~9 s** single-threaded, 97/99 successful refits at R = 99.
- Threading is NOT yet a win on this route: #549 (threaded profile crashes) and #550 (threaded
  bootstrap 7x SLOWER from BLAS oversubscription: 65 s vs 9 s). Use `threads = FALSE` for now.
