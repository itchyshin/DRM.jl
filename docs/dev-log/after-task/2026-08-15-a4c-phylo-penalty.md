# After-task — A4c: penalized-MAP phylogenetic variance components

Date: 2026-08-15 · lane: DRM.jl (Claude, arc-loop) · arc A4c · anchor drmTMB **0.7.0**, installed

## What shipped

`src/phylo_penalty.jl` — `drm_phylo_penalty()`, `drm_phylo_penalty_sweep()`,
`PhyloPenalty`, `PhyloCorPenaltyNeedsTwoSD`. The Julia twin of drmTMB's
`R/penalty.R` + `src/drmTMB.cpp:93`.

Estimated ~1 day in the A4 re-scope; landed inside that.

## Why this is engine capability, not an export gap

The penalty is **added to the negative log-likelihood**, so the estimator stops
being ML and becomes maximum-a-posteriori. Every affected route's objective *and*
its analytic gradient had to carry the extra term — this could not be bolted on
post-fit. Four blocks were wired:

| block | phylo SDs | correlation | file |
|---|---|---|---|
| mean-only sparse | 1 | — | `location_only.jl` `fg!` |
| asymmetric (σ-phylo) | 1 | — | `gaussian_locscale_phylo.jl` |
| separate (both axes) | 2 | constrained to 0 | same |
| coupled (both axes) | 2 | **live** | same |

## The decision that mattered: what `cor_sd` penalises

drmTMB penalises `eta_cor_phylo`, its *unconstrained* correlation. DRM.jl's
coupled block optimises `L21`, a Cholesky off-diagonal. **Penalising `L21`
directly would have been a different prior wearing the same name** — the kind of
port that passes its own tests forever.

So the correlation is recovered first, `cor = L21 / sqrt(L21² + L22²)`, and
`atanh(cor)` is penalised. The chain rule stays closed form —

```
dz/dL21 = 1/r        dz/dlogL22 = -L21/r        r = sqrt(L21² + L22²)
```

— so the routes keep their analytic gradients and no finite differencing crept
in. Verified against finite differences at 1e-9 before any of it was wired up,
not after.

## The other decision: where the penalty value lives

The cheap option was a new key in the `scales` dict. That would have been a
**re-run of the bug the previous arc just fixed**: `sigma()`
(`gaussian_core.jl:975`) returns a bare vector only when `scales` has exactly one
key, so adding a key silently breaks `sigma()`. A-sigma spent a slice on exactly
this. So `DrmFit` gained real `phylo_penalty` / `penalty` fields.

That struct is constructed at ~70 sites across 20 family files. Rather than
touch them all, the two fields were appended and a **19-argument compatibility
constructor** supplies the "absent" defaults, so every pre-existing fitter is
untouched and only `_withmap` can set them.

## Evidence

`tools/parity_phylo_penalty.R` vs native drmTMB 0.7.0, tolerance 1e-4:

```
phylo_penalty_ml_baseline  PARITY_PASS  max|d| = 9.664e-09
phylo_penalty_sd_moderate  PARITY_PASS  max|d| = 7.460e-07
phylo_penalty_sd_tight     PARITY_PASS  max|d| = 9.056e-08
OVERALL: ALL CELLS PASS
```

Three quantities per cell — `sd_phylo`, the penalty, and the **unpenalized**
`logLik` — because agreement on the estimate alone is not evidence that the two
sides mean the same thing by it. That choice paid for itself twice (below).

`test_phylo_penalty.jl`, 73 assertions:

- the penalty equals drmTMB's own closed form `Σ(λ·sd − log sd − log λ)` to 1e-9;
- `penalty = nothing` is **bit-identical** to a plain ML fit;
- shrinkage measured over **10 seeds**: ratio `sd_MAP/sd_ML` mean 0.958, sd
  0.0079, range [0.9495, 0.9761] — the test bound is sized from that, not fitted
  to one run;
- monotone in `sd_u`; correlation monotone in `cor_sd`;
- refusals: no phylo term, REML×penalty, non-`PhyloPenalty`, `cor_sd` on a
  single-SD or zero-correlation block, `algorithm = :em`.

## Two findings the fixture caught

Full write-up: `docs/dev-log/evidence/2026-08-15-a4c-phylo-penalty-parity.md`.

**1. The tree-scale convention differs, and it changes the prior.** The first run
failed the *ML baseline* — no penalty involved — with identical log-likelihoods
and SDs differing by exactly `sqrt(tree height)` (1.23630740 observed vs
1.23630753 predicted). drmTMB standardises via `ape::vcv(tree, corr = TRUE)`;
DRM.jl uses the branch lengths as supplied. Since `sd_u` is a threshold *on that
SD*, **the same `sd_u` is a different prior on the two sides unless the tree has
unit height**. Documented in the `drm_phylo_penalty` docstring with the rescaling
recipe.

The ML baseline cell is what caught it. Without it the failure would have been
read as a penalty bug and debugged in the wrong file.

**2. drmTMB reports its penalty off the optimum (upstream defect).** With scales
reconciled, SDs matched to 7 decimals but `logLik` and `penalty` each differed by
*exactly* 0.003271 — the penalized objective agreed, the split did not. drmTMB
reads the penalty from `fit$obj$report()` with **no argument**, so TMB reports at
`last.par`, a finite-difference perturbation 1e-3 from the optimum. DRM.jl
matches drmTMB's documented formula and its own internal parameter to 15 digits;
the R value is the outlier. Because `logLik <- -opt$objective + phylo_penalty`,
**every penalized drmTMB fit reports a slightly wrong penalty and logLik**
(0.0033 at `sd_u = 0.5`, 0.0094 at `sd_u = 0.25`).

Filed, **not patched**: `R/drmTMB.R` is outside this campaign's narrow drmTMB
lane, and PR #1032 must not be merged. Owner decision.

## Also changed

- `lrtest` / `anova` **refuse** penalized fits — a penalized likelihood ratio has
  no χ² reference distribution. drmTMB emits a note; a silent wrong p-value is
  worse than a refusal.
- `check_drm` gains `penalized_map`, and **drops the gradient criterion for MAP
  fits**: the stored objective is unpenalized, so its gradient is non-zero at the
  MAP optimum by construction. Scoring it would have reported every correct
  penalized fit as broken.
- Reported vcov for a penalized fit is the **penalized** curvature (FD of the
  penalized gradient), which is what a MAP fit should report — with the warning
  that those SEs are credible-interval-shaped.

## Pre-existing bug found in passing, not fixed

`check_drm` throws `ArgumentError: matrix contains Infs or NaNs` on **any** fit
whose `vcov` contains NaN — the normal state of the mean-only sparse phylo route,
which computes only the β block. Reproduces on a plain ML fit on `main`; nothing
to do with A4c. A diagnostic whose purpose is to report trouble should not crash
on it. Filed separately; the A4c test suite works around it by exercising
`penalized_map` on the separate block instead.

## What this arc does NOT cover

- The `sd_phylo(...)` direct-formula refusal drmTMB carries has **no Julia
  counterpart** — DRM.jl has no such route, so nothing was ported.
- `penalty` is wired for the Gaussian phylo routes only. The conjugate-EM variant
  and the dense structured fallback **refuse** it rather than ignore it.
- No non-Gaussian family takes a penalty yet.
- The upstream drmTMB defect is unfixed by design.
