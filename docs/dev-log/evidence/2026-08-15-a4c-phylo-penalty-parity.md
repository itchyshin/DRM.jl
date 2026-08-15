# A4c — phylo-penalty parity, and two things the fixture caught

Date: 2026-08-15 · lane: DRM.jl (Claude, arc-loop) · anchor: drmTMB **0.7.0**, installed
Harness: `tools/parity_phylo_penalty.R` → `docs/dev-log/evidence/parity-phylo-penalty.tsv`

## Result

```
phylo_penalty_ml_baseline  PARITY_PASS  max|d| = 9.664e-09
phylo_penalty_sd_moderate  PARITY_PASS  max|d| = 7.460e-07
phylo_penalty_sd_tight     PARITY_PASS  max|d| = 9.056e-08
OVERALL: ALL CELLS PASS          (tol 1e-4)
```

Each cell compares three quantities, not one: `sd_phylo`, the penalty value, and
the **unpenalized** `logLik`. Agreement on the SD alone would not have been
evidence — two implementations can land on the same estimate while disagreeing
about what they are reporting, which is precisely what happened twice below.

## Finding 1 — the tree-scale convention differs, and it changes the PRIOR

The first run failed the **ML baseline**, with no penalty involved at all:

```
sd 0.8462084 / 0.6844644     ll -44.88965 / -44.88965
```

Identical log-likelihoods, different SDs. Same optimum, two scales. The ratio

```
0.84620840 / 0.68446440 = 1.23630740
sqrt(tree height)       = 1.23630753        (h = 1.52845631)
```

is `sqrt(h)` to seven significant figures. drmTMB builds its phylogenetic
covariance from `ape::vcv(tree, corr = TRUE)` — tips normalised to variance 1 —
while DRM.jl builds its sparse precision from the **Newick branch lengths as
given**, so its tip variance is the tree height.

This is not only a reporting difference. `sd_u` is a threshold *on that SD*, so
on a non-unit-height tree **the same `sd_u` is a different prior on the two
sides**. A user copying `sd_u = 1` out of an R script onto a raw tree of height 2
gets a prior about `sqrt(2)` tighter than they asked for, with nothing to warn
them. The fixture now normalises the tree to unit height, and
`drm_phylo_penalty`'s docstring carries the warning.

**The ML baseline cell is what caught this.** Had the fixture contained only
penalized cells, the failure would have been read as a bug in the penalty and
debugged in the wrong file.

## Finding 2 — drmTMB reports its penalty OFF the optimum (upstream defect)

With the scales reconciled, the SDs matched to 7 decimals but `logLik` and
`penalty` each differed by *exactly the same amount* (0.003271), so the penalized
objective agreed while the split between its two parts did not.

Isolating it against drmTMB's own documented formula:

| quantity | value |
|---|---|
| drmTMB internal `log_sd_phylo` | `-0.33776933188615` |
| `exp(internal)` | `0.713359818285376` |
| `lam*sd - log(sd) - log(lam)` (drmTMB's own C++ formula) | **`2.82150351154948`** |
| `fit$obj$report(last.par.best)` | **`2.82150351154948`** |
| DRM.jl `fit.phylo_penalty` | **`2.82150351154948`** |
| `fit$phylo_penalty` **as drmTMB reports it** | `2.81823157781175` |

drmTMB reads the penalty from `fit$obj$report()` (`R/drmTMB.R` ~line 635) called
with **no argument**, so TMB reports at `obj$env$last.par` — after the
Hessian/`sdreport` step that is a finite-difference perturbation of the optimum
(`max|last.par - last.par.best| = 1e-3` here), not the MLE.

Because `fit$logLik <- -opt$objective + phylo_penalty_value`, the error
propagates: **every penalized drmTMB fit reports a slightly wrong penalty and a
slightly wrong log-likelihood.** The magnitude scales with the penalty — 0.0033
at `sd_u = 0.5`, 0.0094 at `sd_u = 0.25`.

DRM.jl matches drmTMB's *documented formula* and drmTMB's *own internal
parameter* to 15 digits. The R value is the outlier, so the fixture compares
against `report(last.par.best)` and keeps the reported number in the TSV column
`penalty_tmb_reported` — the gap stays visible instead of being silently
absorbed into a tolerance.

Reproducer: `docs/dev-log/evidence/` companion script steps in
`tools/parity_phylo_penalty.R`; the one-line diagnosis is
`all.equal(fit$obj$env$last.par, fit$obj$env$last.par.best) == FALSE`.

**Not fixed here.** `R/drmTMB.R` is outside this campaign's narrow drmTMB lane
(`R/julia-bridge.R`, `tests/testthat/test-julia-*`, `vignettes/julia-engine.Rmd`),
and drmTMB PR #1032 must not be merged. This is an owner decision, filed as a
finding rather than a patch.

## Why this pattern keeps recurring

Both findings are the A-nb2 lesson again: **a self-consistent implementation
cannot detect a shared or definitional error.** DRM.jl's own test suite asserts
the penalty against its own formula and passes either way; drmTMB's own test
suite asserts `expect_equal(pen, expected_pen, tolerance = 1e-6)` against a
value it computes in R rather than the one it reports, so it passes too. Only a
cross-implementation comparison on identical data made the disagreement visible.

That is the argument for keeping the parity fixtures, and for making each one
compare *several* quantities rather than the single headline number.
